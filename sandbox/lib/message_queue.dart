// Copyright (c) 2017, Andreas 'blackhc' Kirsch. All rights reserved. Use of
// this source code is governed by a BSD-style license that can be found in the
// LICENSE file.

import 'dart:async';
import 'dart:collection';

/// Simple queue of future messages.
///
/// It contains two queues internally. One that stores messages that
/// have been received but not requested yet (via `receive()`).
/// And one queue of unfulfilled requests (via `receive()`).
///
///
/// Every time I try to use Streams, I feel stupid :( So let's not do that.
class MessageQueue {
  final messageQueue = new Queue<Object>();
  final receiverQueue = new Queue<Completer<Object>>();

  void addMessage(Object message) {
    if (receiverQueue.isNotEmpty) {
      final completer = receiverQueue.removeFirst();
      completer.complete(message);
      return;
    }
    messageQueue.addLast(message);
  }

  Future<Object> receive() async {
    if (messageQueue.isNotEmpty) {
      return messageQueue.removeFirst();
    }
    final completer = new Completer<Object>();
    receiverQueue.addLast(completer);
    return completer.future;
  }
}
