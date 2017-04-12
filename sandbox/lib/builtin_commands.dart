import 'dart:async';
import 'dart:isolate';
import 'package:dart_repl_sandbox/isolate_messages.dart';
import 'package:dart_repl_sandbox/message_channel.dart';

MessageSender sandboxRequestSender;

void import(String path) {
  sandboxRequestSender.send(new ImportLibraryRequest(path));
}

void exit() {
  sandboxRequestSender.send(new ExitRequest());
}

/* This is not working at the moment. Tracking issue:
https://github.com/dart-lang/sdk/issues/29332

Future loadPackage(String packageName) async {
  sandboxRequestSender.send(new LoadPackageRequest(
      packageName, (await Isolate.packageConfig).toString()));
}
*/
