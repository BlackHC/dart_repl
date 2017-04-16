// Copyright (c) 2016, Andreas 'blackhc' Kirsch. All rights reserved. Use of
// this source code is governed by a BSD-style license that can be found in the
// LICENSE file.

import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';
import 'package:dart_repl/src/package_utils.dart';
import 'package:dart_repl/src/sandbox_isolate.dart';
import 'package:dart_repl/src/cell_type.dart';
import 'package:dart_repl_sandbox/builtin_commands/messages.dart';
import 'package:dart_repl_sandbox/data_queue.dart';
import 'package:dart_repl_sandbox/isolate_messages.dart';
import 'package:dart_repl_sandbox/message_queue.dart';
import 'package:pub_cache/pub_cache.dart';
import 'package:vm_service_client/vm_service_client.dart';
import 'package:dart_repl_sandbox/message_channel.dart';

Future<Null> runRepl(SandboxIsolate sandboxIsolate) async {
  final client =
      new VMServiceClient.connect((await Service.getInfo()).serverUri);

  final sandboxRequestReceiver = new ReceivePort();
  try {
    final vm = await client.getVM();

    print(vm.versionString);
    print('Type `exit()` to quit.');

    final runnableIsolate =
        await getRunnableIsolate(vm, sandboxIsolate.isolate);
    final sandboxLibrary = await runnableIsolate.libraries.values
        .firstWhere((ref) => ref.name == 'sandbox')
        .load();

    final channel = new MessageChannel.fromPorts(sandboxIsolate.receiverQueue,
        CellReplyConverters, sandboxIsolate.sendPort, CellCommandConverters);

    channel
        .sendReceive(new RegisterRequestPort(sandboxRequestReceiver.sendPort));

    final sandboxRequestDataQueue = new DataQueue();
    sandboxRequestReceiver
        .listen((Object data) => sandboxRequestDataQueue.add(data));
    final sandboxRequestQueue = new MessageQueue(
        sandboxRequestDataQueue, SandboxRequestQueueConverters);

    CommandLoop:
    while (true) {
      stdout.write('>>> ');

      final input = stdin.readLineSync();
      if (input.isEmpty) {
        continue;
      }

      try {
        await channel.sendReceive(new ResetResult());

        final cellType = determineCellType(input);
        final eatNull = await executeCell(
            cellType, input, sandboxIsolate, runnableIsolate, sandboxLibrary);

        final cellResult =
            await channel.sendReceive(new CompleteResult()) as CellResult;

        final resultText = cellResult?.result;
        if (resultText != null || !eatNull) {
          print(resultText);
        }

        await channel.sendReceive(new SaveCell(input));

        // Process all the cell requests now.
        // TODO: we would actually want to wait for the whole event queue to be
        // empty. Maybe we need to ping the isolate?
        final sandboxRequests = sandboxRequestQueue.receiveAllQueued();
        for (final sandboxRequest in sandboxRequests) {
          if (sandboxRequest is ImportLibraryRequest) {
            await executeImport(
                sandboxIsolate, runnableIsolate, sandboxRequest);
          } else if (sandboxRequest is ExitRequest) {
            break CommandLoop;
          } else if (sandboxRequest is LoadPackageRequest) {
            await executeLoadPackage(
                sandboxIsolate, runnableIsolate, sandboxRequest);
          } else if (sandboxRequest is HotReloadRequest) {
            await reloadCode(runnableIsolate);
          } else {
            throw new StateError("Unknown sandbox request $sandboxRequest!");
          }
        }
      } on VMErrorException catch (errorRef) {
        print(errorRef.error.message);
      }
    }
  } finally {
    sandboxIsolate.isolate.kill();
    client.close();
    sandboxRequestReceiver.close();
  }
}

/// Execute input as cellType.
///
/// Tries to append ; to fix missing ;s
///
/// Returns whether to eat 'null' results or not.
Future<bool> executeCell(
    CellType cellType,
    String input,
    SandboxIsolate sandboxIsolate,
    VMRunnableIsolate runnableIsolate,
    VMLibrary sandboxLibrary) async {
  bool eatNull = true;
  if (cellType == CellType.UNKNOWN) {
    final fixedInput = input + ';';
    final fixedCellType = determineCellType(fixedInput);
    if (fixedCellType != CellType.UNKNOWN) {
      return executeCell(fixedCellType, fixedInput, sandboxIsolate,
          runnableIsolate, sandboxLibrary);
    }
  }
  switch (cellType) {
    case CellType.TOP_LEVEL:
      await linkAndExecuteCell(sandboxIsolate, input, runnableIsolate);
      break;
    case CellType.STATEMENTS:
      await sandboxLibrary.evaluate('result__ = () { $input }()');
      break;
    case CellType.EXPRESSION:
      // TODO: to determine whether to eat null, we need to know the actual
      // type of the expression as void also returns null...
      await sandboxLibrary.evaluate('result__ = $input');
      eatNull = false;
      break;
    case CellType.AWAIT_EXPRESSION:
      await sandboxLibrary.evaluate('result__ = (() async => $input)()');
      eatNull = false;
      break;
    case CellType.UNKNOWN:
      print('Syntax not supported. Trying...');
      await sandboxLibrary.evaluate('$input');
      break;
  }
  return eatNull;
}

final pubCache = new PubCache();

Future executeLoadPackage(SandboxIsolate sandboxIsolate,
    VMRunnableIsolate runnableIsolate, LoadPackageRequest request) async {
  final packageRef = pubCache.getLatestVersion(request.packageName);
  final libPath = packageRef.resolve().location.path + "/lib/";
  final newPackageResolver =
      await addPackage(request.packageConfigUri, request.packageName, libPath);
  final packageConfigUri = await newPackageResolver.packageConfigUri;
  final report = await runnableIsolate.reloadSources(
      force: true, packagesUrl: packageConfigUri);
  if (!report.status) {
    print(report.message);
  }
}

Future executeImport(
    SandboxIsolate sandboxIsolate,
    VMRunnableIsolate runnableIsolate,
    ImportLibraryRequest importLibraryRequest) async {
  await linkAndExecuteCell(sandboxIsolate,
      "export \'${importLibraryRequest.libraryPath}\';", runnableIsolate);
}

Future linkAndExecuteCell(SandboxIsolate sandboxIsolate, String input,
    VMRunnableIsolate runnableIsolate) async {
  sandboxIsolate.cellChain.addCell(input);
  //print('reload sources');
  final report = await runnableIsolate.reloadSources();
  if (!report.status) {
    print(report.message);
    // Undo the last cell, so we can try again.
    sandboxIsolate.cellChain.undoCell();
  }
}

Future reloadCode(VMRunnableIsolate runnableIsolate) async {
  final report = await runnableIsolate.reloadSources();
  if (!report.status) {
    print(report.message);
  }
}

Future<VMRunnableIsolate> getRunnableIsolate(VM vm, Isolate isolate) async {
  final isolates = await vm.isolates;

  // Find the isolate that we are running in.
  final isolateId = Service.getIsolateID(isolate);
  final serviceIsolate = isolates.firstWhere(
      (isolate) => 'isolates/${isolate.numberAsString}' == isolateId);

  final runnable = await serviceIsolate.loadRunnable();
  return runnable;
}

Future main() async {
//  final sandboxIsolate = await bootstrapIsolate(
//      packageDir: '/Users/blackhc/git/built_collection.dart',
//      imports: ['lib/built_collection.dart']);
  final sandboxIsolate = await bootstrapIsolate();
  await runRepl(sandboxIsolate);
}
