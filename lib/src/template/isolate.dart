// Copyright (c) 2016, Andreas 'blackhc' Kirsch. All rights reserved. Use of
// this source code is governed by a BSD-style license that can be found in the
// LICENSE file.

import 'dart:async';
import 'dart:isolate';

// TODO: recreate a dart_repl_sandbox package to fix these warnings?
import 'package:dart_repl_sandbox/builtin_commands/api.dart' as builtins;
import 'package:dart_repl_sandbox/builtin_commands/messages.dart';
import 'package:dart_repl_sandbox/cell.dart';
import 'package:dart_repl_sandbox/cell_environment.dart' as cell_environment;
import 'package:dart_repl_sandbox/data_queue.dart';
import 'package:dart_repl_sandbox/isolate_messages.dart';

// Include the head of the cell chain. This is important for reload sources to
// work.
// The kernel code uses reflection to find this library.
import 'package:dart_repl_sandbox/message_channel.dart';

// This is needed to load all the symbols and make them available to the
// environment at runtime.
import 'sandbox.dart';

Future main(List<String> args, SendPort sendPort) async {
  final receivePort = new ReceivePort();
  sendPort.send(receivePort.sendPort);

  // Communications channel are now established.
  final dataQueue = new DataQueue();
  receivePort.listen((Object data) => dataQueue.add(data));

  // TODO: rename fromPorts
  final channel = new MessageChannel.fromPorts(
      dataQueue, CellCommandConverters, sendPort, CellReplyConverters);

  do {
    final message = await channel.receive();
    //print(message?.toRawMessage());
    if (message is CompleteResult) {
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
        channel.send(new CellResult('${cell_environment.result__}'));
      } else {
        channel.send(new CellResult(null));
      }
    } else if (message is ResetResult) {
      cell_environment.result__ = null;
      channel.send(null);
    } else if (message is SaveCell) {
      cell_environment.Cell
          .add(new Cell(message.input, cell_environment.result__));
      channel.send(null);
    } else if (message is RegisterRequestPort) {
      builtins.sandboxRequestSender =
          new MessageSender(message.sendPort, SandboxRequestQueueConverters);
      channel.send(null);
    } else {
      throw new StateError('Unknown message $message!');
    }
  } while (true);
}
