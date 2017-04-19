import 'dart:async';
import 'package:dart_repl_sandbox/data_queue.dart';
import 'package:dart_repl_sandbox/message_converter.dart';

/// Wrapper around DataQueue that converts messages to raw messages and back.
class MessageQueue {
  final DataQueue dataQueue;
  final MessageConverter converter;

  MessageQueue(this.dataQueue, this.converter);

  void add(Object data) {
    dataQueue.add(data);
  }

  Future<Message> receive() async {
    Object data = await dataQueue.receive();
    if (data == null) {
      return null;
    }
    // I don't understand why I can't leave out the <Object> here.
    return converter.fromRawMessage<Message>(data);
  }

  Iterable<Message> receiveAllQueued() {
    final messages = dataQueue.dataQueue
        .toList()
        .map<Message>((Object data) => converter.fromRawMessage(data));
    dataQueue.dataQueue.clear();
    return messages;
  }
}
