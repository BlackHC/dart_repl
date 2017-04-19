// Copyright (c) 2017, Andreas 'blackhc' Kirsch. All rights reserved. Use of
// this source code is governed by a BSD-style license that can be found in the
// LICENSE file.

import 'dart:async';
import 'dart:collection';

/// Simple queue of future data.
///
/// It contains two queues internally. One that stores data that
/// have been received but not requested yet (via `receive()`).
/// And one queue of unfulfilled requests (via `receive()`).
///
/// Note:
/// Every time I try to use Streams, I feel stupid :( So let's not do that.
class DataQueue {
  final dataQueue = new Queue<Object>();
  final receiverQueue = new Queue<Completer<Object>>();

  void add(Object message) {
    if (receiverQueue.isNotEmpty) {
      final completer = receiverQueue.removeFirst();
      completer.complete(message);
      return;
    }
    dataQueue.addLast(message);
  }

  Future<Object> receive() async {
    if (dataQueue.isNotEmpty) {
      return dataQueue.removeFirst();
    }
    final completer = new Completer<Object>();
    receiverQueue.addLast(completer);
    return completer.future;
  }
}
