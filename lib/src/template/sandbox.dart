// Copyright (c) 2016, Andreas 'blackhc' Kirsch. All rights reserved. Use of
// this source code is governed by a BSD-style license that can be found in the
// LICENSE file.

/// This library name is needed to find the library using reflection.
library sandbox;

// Make Futures and Streams available.
import 'dart:async';

import 'package:dart_repl_sandbox/scope.dart' as scope_;

// Import the cell environment.
import 'package:dart_repl_sandbox/cell_environment.dart';

import 'package:dart_repl_sandbox/builtin_commands.dart';

// TODO: this duplicates most of cell_template.dart :((

/*{SOURCE}*/

// By importing this after source, __env cannot be hidden.
import 'package:dart_repl_sandbox/cell_environment.dart' as __env;
