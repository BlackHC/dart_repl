// Copyright (c) 2016, Andreas 'blackhc' Kirsch. All rights reserved. Use of
// this source code is governed by a BSD-style license that can be found in the
// LICENSE file.

import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';
import 'package:dart_repl/src/sandbox_isolate.dart';
import 'package:dart_repl/src/cell_type.dart';
import 'package:dart_repl/src/sandbox/isolate_messages.dart';
import 'package:vm_service_client/vm_service_client.dart';

Future<Null> runRepl(SandboxIsolate sandboxIsolate) async {
  final client =
      new VMServiceClient.connect((await Service.getInfo()).serverUri);

  try {
    final vm = await client.getVM();

    print(vm.versionString);
    print('Type `exit()` to quit.');

    final runnableIsolate =
        await getRunnableIsolate(vm, sandboxIsolate.isolate);
    final sandboxLibrary = await runnableIsolate.libraries.values
        .firstWhere((ref) => ref.name == 'sandbox')
        .load();

    while (true) {
      stdout.write('>>> ');

      final input = stdin.readLineSync();
      if (input == 'exit()') {
        break;
      } else if (input.isEmpty) {
        continue;
      }

      try {
        sandboxIsolate.sendPort.send(RESET_RESULT);
        await sandboxIsolate.receiverQueue.receive();
        final cellType = determineCellType(input);
        final eatNull = await executeCell(
            cellType, input, sandboxIsolate, runnableIsolate, sandboxLibrary);

        sandboxIsolate.sendPort.send(COMPLETE_RESULT);
        final resultText =
            await sandboxIsolate.receiverQueue.receive() as String;
        if (resultText != null || !eatNull) {
          print(resultText);
        }

        sandboxIsolate.sendPort.send({'type': SAVE_CELL, 'input': input});
        await sandboxIsolate.receiverQueue.receive();
      } on VMErrorException catch (errorRef) {
        print(errorRef.error.message);
      }
    }
  } finally {
    sandboxIsolate.isolate.kill();
    client.close();
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
      sandboxIsolate.cellChain.addCell(input);
      //print('reload sources');
      final report = await runnableIsolate.reloadSources();
      if (!report.status) {
        print(report.message);
        // Undo the last cell, so we can try again.
        sandboxIsolate.cellChain.undoCell();
      }
      break;
    case CellType.STATEMENTS:
      await sandboxLibrary.evaluate('result__ = () { $input }()');
      break;
    case CellType.EXPRESSION:
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
  final sandboxIsolate = await bootstrapIsolate(
      packageDir: '/Users/blackhc/git/built_collection.dart',
      imports: ['lib/built_collection.dart']);
  await runRepl(sandboxIsolate);
}
