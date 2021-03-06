// Copyright (c) 2017, Andreas 'blackhc' Kirsch. All rights reserved. Use of
// this source code is governed by a BSD-style license that can be found in the
// LICENSE file.

typedef T FromMessage<T>(Object simpleFormat);

class MessageConverter {
  final Map<String, FromMessage> messageConverters;

  MessageConverter(Map<Type, FromMessage> messageConverters)
      : messageConverters = prepareMessageBuilders(messageConverters);

  static Map<String, FromMessage> prepareMessageBuilders(
          Map<Type, FromMessage> map) =>
      new Map<String, FromMessage>.fromIterables(
          map.keys.map((type) => type.toString()), map.values);

  T fromRawMessage<T>(Object rawMessage) {
    if (rawMessage is String) {
      final typeString = rawMessage;
      return messageConverters[typeString](null) as T;
    } else if (rawMessage is Map) {
      final typeString = rawMessage['type'] as String;
      final simpleObject = rawMessage['data'] as Object;
      return messageConverters[typeString](simpleObject) as T;
    }
    throw new ArgumentError.value(
        rawMessage, 'message', 'expected String or Map!');
  }

  static Object encapsulateRawData(Type type, Object rawData) => rawData != null
      ? {'type': type.toString(), 'data': rawData}
      : type.toString();

  Object toRawMessage(Message message) {
    // TODO: Check to make sure we know how to deserialize message.
    return message.toRawMessage();
  }
}

abstract class Message<T> {
  /// "Override" and add to a MessageConverters instance to build a
  static Message fromRawMessage(Object rawMessage) => null;

  /// Override to return raw data.
  Object toRawData() => null;
  Object toRawMessage() => MessageConverter.encapsulateRawData(T, toRawData());
}
