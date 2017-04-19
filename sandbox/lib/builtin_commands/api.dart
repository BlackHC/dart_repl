// Copyright (c) 2017, Andreas 'blackhc' Kirsch. All rights reserved. Use of
// this source code is governed by a BSD-style license that can be found in the
// LICENSE file.

import 'dart:async';
import 'dart:isolate';
import 'package:dart_repl_sandbox/builtin_commands/messages.dart';
import 'package:dart_repl_sandbox/message_channel.dart';

MessageSender sandboxRequestSender;

void import(String path) {
  sandboxRequestSender.send(new ImportLibraryRequest(path));
}

void exit() {
  sandboxRequestSender.send(new ExitRequest());
}

void reload() {
  sandboxRequestSender.send(new HotReloadRequest());
}

/* This is not working at the moment. Tracking issue:
https://github.com/dart-lang/sdk/issues/29332
*/
Future loadPackage(String packageName) async {
  sandboxRequestSender.send(new LoadPackageRequest(
      packageName, (await Isolate.packageConfig).toString()));
}

