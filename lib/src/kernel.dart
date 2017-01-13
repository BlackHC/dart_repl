// Copyright (c) 2016, Andreas 'blackhc' Kirsch. All rights reserved. Use of
// this source code is governed by a BSD-style license that can be found in the
// LICENSE file.

import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';
import 'package:dart_repl/src/sandbox_isolate.dart';
import 'package:dart_repl/src/cell_type.dart';
import 'package:dart_repl_sandbox/isolate_messages.dart';
import 'package:vm_service_client/vm_service_client.dart';

Future runRepl(SandboxIsolate sandboxIsolate) async {
  final client =
      new VMServiceClient.connect((await Service.getInfo()).serverUri);

  try {
    final vm = await client.getVM();

    print(vm.versionString);
    print('Type `exit()` to quit.');

    final runnableIsolate =
        await getRunnableIsolate(vm, sandboxIsolate.isolate);
    final scopeLibrary = await runnableIsolate.rootLibrary.load();

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
        final scopeField = await scopeLibrary.fields['isolateScope'].load();
        if (isExpression(input)) {
          await scopeField.value.evaluate('result__ = $input');
        } else if (isStatements(input)) {
          await scopeField.value.evaluate('() { $input }()');
        } else {
          print('Syntax not supported. Trying...');
          await scopeField.value.evaluate('$input');
        }

        sandboxIsolate.sendPort.send(COMPLETE_RESULT);
        final resultText =
            await sandboxIsolate.receiverQueue.receive() as String;
        if (resultText != null) {
          print(resultText);
        }

        sandboxIsolate.sendPort.send({'type': SAVE_CELL, 'input': input});
        await sandboxIsolate.receiverQueue.receive();
      } on VMErrorException catch (errorRef) {
        print(errorRef);
      }
    }
  } finally {
    sandboxIsolate.isolate.kill();
    client.close();
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
  final sandboxIsolate = await bootstrapIsolate(
      packageDir: '/home/blackhc/git/built_collection.dart',
      imports: ['lib/built_collection.dart']);
  await runRepl(sandboxIsolate);
}
