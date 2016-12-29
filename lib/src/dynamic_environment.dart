// Copyright (c) 2016, Andreas 'blackhc' Kirsch. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.
// This library name is important for the execution code to find it dynamically.
library dynamic_environment;

import 'dart:collection';
import 'dart:io';
import 'dart:async';

import 'package:dart_repl/src/scope.dart' as scope_;

// Import the cell environment.
import 'package:dart_repl/src/cell_environment.dart';

/*${IMPORTS}*/

// Bind the scope instances to this library to allow it to find symbols
// exposed to this library.
class Scope extends scope_.Scope {}
