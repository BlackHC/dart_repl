// Copyright (c) 2017, Andreas 'blackhc' Kirsch. All rights reserved. Use of
// this source code is governed by a BSD-style license that can be found in the
// LICENSE file.

/*{LIBRARY}*/

// Make Futures and Streams available in general.
import 'dart:async';

// Import the cell environment.
import 'package:dart_repl_sandbox/cell_environment.dart';

// Provide builtin commands like `exit` or `import`.
import 'package:dart_repl_sandbox/builtin_commands/api.dart';

/*{IMPORTS}*/

// By importing after the other imports, __env and __api cannot be hidden.
import 'package:dart_repl_sandbox/cell_environment.dart' as __env;
import 'package:dart_repl_sandbox/builtin_commands/api.dart' as __api;

/*{SOURCE}*/
