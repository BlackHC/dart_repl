import 'package:dart_repl_sandbox/isolate_messages.dart';
import 'package:dart_repl_sandbox/message_channel.dart';

MessageSender sandboxRequestSender;

void import(String path) {
  sandboxRequestSender.send(new ImportLibraryRequest(path));
}
