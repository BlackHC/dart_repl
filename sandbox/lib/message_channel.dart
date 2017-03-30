import 'dart:async';
import 'dart:isolate';
import 'package:dart_repl_sandbox/data_queue.dart';
import 'package:dart_repl_sandbox/message_converter.dart';
import 'package:dart_repl_sandbox/message_queue.dart';


class MessageSender {
  final SendPort sendPort;
  final MessageConverter sendConverter;

  MessageSender(this.sendPort, this.sendConverter);

  void send<T extends Message<T>>(T object) {
    if (object != null) {
      final rawMessage = sendConverter.toRawMessage(object);
      sendPort.send(rawMessage);
    } else {
      sendPort.send(null);
    }
  }
}

class MessageChannel {
  final MessageQueue receiver;
  final MessageSender sender;

  MessageChannel(this.receiver, this.sender);
  factory MessageChannel.fromPorts(DataQueue dataQueue, MessageConverter receiverConverter, SendPort sendPort, MessageConverter sendConverter) {
    final receiver = new MessageQueue(dataQueue, receiverConverter);
    final sender = new MessageSender(sendPort, sendConverter);
    return new MessageChannel(receiver, sender);
  }

  void send(Message message) {
    sender.send(message);
  }

  Future<Message> receive() {
    return receiver.receive();
  }

  Future<Message> sendReceive(Message message) {
    send(message);
    return receive();
  }
}
