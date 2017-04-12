// Copyright (c) 2016, Andreas 'blackhc' Kirsch. All rights reserved. Use of
// this source code is governed by a BSD-style license that can be found in the
// LICENSE file.

/// This library name is needed to find the library using reflection.
library sandbox;

// Make Futures and Streams available.
import 'dart:async';

// Import the cell environment.
import 'package:dart_repl_sandbox/cell_environment.dart';
// Import builtin commands such as `import` or `exit`.
import 'package:dart_repl_sandbox/builtin_commands/api.dart';

/*{SOURCE}*/

// By importing after the current cell, __env and __api cannot be hidden by it.
import 'package:dart_repl_sandbox/cell_environment.dart' as __env;
import 'package:dart_repl_sandbox/builtin_commands/api.dart' as __api;
