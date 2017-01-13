// Copyright (c) 2016, Andreas 'blackhc' Kirsch. All rights reserved. Use of
// this source code is governed by a BSD-style license that can be found in the
// LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:dart_repl_sandbox/cell.dart';
import 'package:dart_repl_sandbox/scope.dart' as scope;
import 'package:dart_repl_sandbox/cell_environment.dart' as cell_environment;
import 'package:dart_repl_sandbox/isolate_messages.dart';

import 'dynamic_environment.dart';

// Scope from dynamic_environment is lexically bound to imports in that library.
Scope isolateScope;

Future main(List<String> args, SendPort sendPort) async {
  final receivePort = new ReceivePort();
  sendPort.send(receivePort.sendPort);
  // Communications channel are now established.

  // Create the main scope.
  isolateScope = new Scope();

  receivePort.listen((Object message) async {
    if (message == COMPLETE_RESULT) {
      if (cell_environment.result__ is Future) {
        // TODO: this should be signaled using a response message!
        print('(Awaiting result...)');
        cell_environment.result__ = await cell_environment.result__;
      }
      if (cell_environment.result__ is Stream) {
        // TODO: this should be signaled using a response message!
        print('(Reading stream...)');
        cell_environment.result__ =
            await (cell_environment.result__ as Stream).toList();
      }

      if (cell_environment.result__ != null) {
        sendPort.send('${cell_environment.result__}');
      } else {
        sendPort.send(null);
      }
    } else if (message == RESET_RESULT) {
      cell_environment.result__ = null;
      sendPort.send(null);
    } else if (message is Map && message['type'] == SAVE_CELL) {
      final input = message['input'] as String;
      cell_environment.Cell.add(new Cell(new scope.Scope.clone(isolateScope),
          input, cell_environment.result__));
      sendPort.send(null);
    } else {
      throw 'Unknown message $message!';
    }
  });
}
