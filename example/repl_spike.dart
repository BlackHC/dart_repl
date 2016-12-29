// Copyright (c) 2016, Andreas 'blackhc' Kirsch. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:vm_service_client/vm_service_client.dart';
import 'dart:io';

class ExecutionScope {
  static final results = <dynamic>[];

  static set result(dynamic value) {
    results.add(value);
  }
}

Future main(List<String> args) async {
  VMServiceClient client = getOwnVmServiceClient();

  final vm = await client.getVM();
  print(vm.versionString);
  final isolates = await vm.isolates;

  final isolate = isolates.first;
  print('Type `exit()` to quit.');
  await repl(isolate);

  await client.close();
}

Future repl(VMIsolateRef isolate) async {
  final runnable = await isolate.loadRunnable();
  final rootLibrary = await runnable.rootLibrary.load();
  final executionScope = await rootLibrary.classes['ExecutionScope'].load();

  while(true) {
    stdout.write('>>> ');

    final input = stdin.readLineSync();
    if (input == 'exit()') {
      break;
    }
    try {
      final result = await executionScope.evaluate(input);
      final value = await result.getValue();
      if (value != null) print(value);
    }
    on VMErrorException catch (errorRef) {
      print(errorRef);
    }
  }
}

VMServiceClient getOwnVmServiceClient() {
  final vmFlags = Platform.executableArguments;
  final vmServiceFlag = vmFlags.last;
  // Intellij starts Dart with --enableVmService:XXXX
  final servicePort = int.parse(vmServiceFlag.split(':')[1]);

  final url = "ws://localhost:$servicePort/ws";
  final client = new VMServiceClient.connect(url);
  return client;
}