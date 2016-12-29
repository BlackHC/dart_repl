// Copyright (c) 2016, Andreas 'blackhc' Kirsch. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:developer';
import 'dart:isolate';
import 'dart:mirrors';

import 'package:dart_repl/src/cell.dart';
import 'package:dart_repl/src/cell_type.dart';
import 'package:dart_repl/src/sandbox.dart';
import 'package:dart_repl/src/scope.dart';
import 'package:vm_service_client/vm_service_client.dart';
import 'package:dart_repl/src/execution_environment.dart' as sandbox;

Future main(List<String> args) async {
  await repl();
}

class ExecutionEnvironmentProxy {
  final libraryMirror =
      currentMirrorSystem().findLibrary(#execution_environment);

  dynamic get result => libraryMirror.getField(#result__).reflectee;
  void set result(dynamic value) {
    libraryMirror.setField(#result__, value);
  }

  Scope get scope => libraryMirror.getField(#scope__).reflectee;
  List<Cell> get cells => libraryMirror.getField(#Cell).reflectee;
}

Future repl() async {
  final client =
      new VMServiceClient.connect((await Service.getInfo()).serverUri);

  final vm = await client.getVM();

  print(vm.versionString);
  print('Type `exit()` to quit.');

  final isolates = await vm.isolates;

  // Find the isolate that we are running in.
  final isolateId = Service.getIsolateID(Isolate.current);
  final isolate = isolates.firstWhere(
      (isolate) => 'isolates/${isolate.numberAsString}' == isolateId);

  final runnable = await isolate.loadRunnable();
  final sandboxLibrary = await runnable
      .libraries[Uri.parse('package:dart_repl/src/execution_environment.dart')]
      .load();

  final executionEnvironmentProxy = new ExecutionEnvironmentProxy();
  // Touch the scope to ensure it exists.
  executionEnvironmentProxy.scope;

  while (true) {
    stdout.write('>>> ');

    final input = stdin.readLineSync();
    if (input == 'exit()') {
      break;
    }
    try {
      executionEnvironmentProxy.result = null;
      final scopeField = await sandboxLibrary.fields['scope__'].load();
      if (isExpression(input)) {
        await scopeField.value.evaluate('result__ = $input');
      } else if (isStatements(input)) {
        await scopeField.value.evaluate('() { $input }()');
      } else {
        print('Syntax not supported. Trying...');
        await scopeField.value.evaluate('$input');
      }

      if (executionEnvironmentProxy.result is Future) {
        print('(Awaiting result...)');
        executionEnvironmentProxy.result =
            await executionEnvironmentProxy.result;
      }
      if (executionEnvironmentProxy.result is Stream) {
        executionEnvironmentProxy.result =
            (executionEnvironmentProxy.result as Stream).toList();
      }
      if (executionEnvironmentProxy.result != null) {
        print(executionEnvironmentProxy.result);
      }
      executionEnvironmentProxy.cells.add(new Cell(
          new Scope.clone(executionEnvironmentProxy.scope),
          input,
          executionEnvironmentProxy.result));
    } on VMErrorException catch (errorRef) {
      print(errorRef);
    }
  }
}
