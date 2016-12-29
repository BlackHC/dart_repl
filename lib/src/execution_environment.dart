// Copyright (c) 2016, Andreas 'blackhc' Kirsch. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.
// This library name is important for the execution code to find it dynamically.
library execution_environment;

import 'dart:collection';
import 'dart:io';
import 'dart:async';

import 'package:dart_repl/src/cell.dart' as cell_;
import 'package:dart_repl/src/scope.dart' as scope_;

/*${IMPORTS}*/

// Bind the scope instances to this library to allow it to find symbols
// exposed to this library.
class Scope extends scope_.Scope {}

Scope scope__ = new Scope();
Object result__;

final Cell = <cell_.Cell>[];
final Out = new cell_.CellAccessor<dynamic>(Cell, (cell) => cell.output);
final In = new cell_.CellAccessor<String>(Cell, (cell) => cell.input);

dynamic get _ => Out.last;
dynamic get __ => Out[Out.length - 2];
dynamic get ___ => Out[Out.length - 2];