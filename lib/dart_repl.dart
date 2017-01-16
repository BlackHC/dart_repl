// Copyright (c) 2016, Andreas 'blackhc' Kirsch. All rights reserved. Use of
// this source code is governed by a BSD-style license that can be found in the
// LICENSE file.

import 'dart:async';
import 'dart:developer';

import 'package:dart_repl/src/sandbox_isolate.dart';
import 'package:dart_repl/src/kernel.dart';

Future dartRepl(
    {String packageDir, List<String> imports = const <String>[]}) async {
  await Service.controlWebServer(enable: true);

  final sandboxIsolate =
      await bootstrapIsolate(packageDir: packageDir, imports: imports);
  await runRepl(sandboxIsolate);
}
