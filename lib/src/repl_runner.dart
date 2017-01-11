// Copyright (c) 2016, Andreas 'blackhc' Kirsch. All rights reserved. Use of 
// this source code is governed by a BSD-style license that can be found in the 
// LICENSE file.
import 'dart:async';
import 'package:dart_repl/src/repl.dart';

// This is included here, so it can be customized with new imports.
import 'package:dart_repl/src/dynamic_environment.dart';

Future main() async {
  await repl();
}
