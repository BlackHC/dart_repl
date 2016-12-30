// Copyright (c) 2016, Andreas 'blackhc' Kirsch. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.
library repl;

import 'dart:async';
import 'dart:io';
import 'dart:developer';
import 'dart:isolate';
import 'dart:mirrors';

import 'package:dart_repl/src/cell.dart';
import 'package:dart_repl/src/cell_type.dart';
import 'package:dart_repl/src/scope.dart';
import 'package:vm_service_client/vm_service_client.dart';
import 'package:dart_repl/src/cell_environment.dart' as cell_environment;

Future repl() async {
  final client =
      new VMServiceClient.connect((await Service.getInfo()).serverUri);

  try {
    final vm = await client.getVM();

    print(vm.versionString);
    print('Type `exit()` to quit.');

    final runnableIsolate = await getRunnableIsolateSelf(vm);
    final scopeLibrary = await runnableIsolate.libraries.values
        .firstWhere((libraryRef) => libraryRef.name == 'scope')
        .load();

    currentScope = createDynamicScope();

    while (true) {
      stdout.write('>>> ');

      final input = stdin.readLineSync();
      if (input == 'exit()') {
        break;
      } else if (input.isEmpty) {
        continue;
      }

      try {
        cell_environment.result__ = null;
        final scopeField = await scopeLibrary.fields['currentScope'].load();
        if (isExpression(input)) {
          await scopeField.value.evaluate('result__ = $input');
        } else if (isStatements(input)) {
          await scopeField.value.evaluate('() { $input }()');
        } else {
          print('Syntax not supported. Trying...');
          await scopeField.value.evaluate('$input');
        }

        if (cell_environment.result__ is Future) {
          print('(Awaiting result...)');
          cell_environment.result__ = (await cell_environment.result__);
        }
        if (cell_environment.result__ is Stream) {
          print('(Reading stream...)');
          cell_environment.result__ =
              await ((cell_environment.result__ as Stream).toList());
        }

        if (cell_environment.result__ != null) {
          print(cell_environment.result__);
        }

        cell_environment.Cell.add(new Cell(
            new Scope.clone(currentScope), input, cell_environment.result__));
      } on VMErrorException catch (errorRef) {
        print(errorRef);
      }
    }
  } finally {
    client.close();
  }
}

Scope createDynamicScope() {
  final libraryMirror = currentMirrorSystem().findLibrary(#dynamic_environment);
  final scopeClassMirror = libraryMirror.declarations[#Scope] as ClassMirror;
  final scope = scopeClassMirror.newInstance(
      new Symbol(''), <dynamic>[], <Symbol, dynamic>{}).reflectee as Scope;
  return scope;
}

Future<VMRunnableIsolate> getRunnableIsolateSelf(VM vm) async {
  final isolates = await vm.isolates;

  // Find the isolate that we are running in.
  final isolateId = Service.getIsolateID(Isolate.current);
  final isolate = isolates.firstWhere(
      (isolate) => 'isolates/${isolate.numberAsString}' == isolateId);

  final runnable = await isolate.loadRunnable();
  return runnable;
}
