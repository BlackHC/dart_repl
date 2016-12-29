// Copyright (c) 2016, Andreas 'blackhc' Kirsch. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:async';

import 'package:dart_repl/src/cell.dart' as cell_;
import 'package:dart_repl/src/scope.dart' as scope_;

/*${IMPORTS}*/

// Bind the scope instances to this library.
class Scope extends scope_.Scope {}

Scope scope__ = new Scope();
Object result__;

List<cell_.Cell> cell = [];
List<dynamic> get out =>
    cell.map<dynamic>((cell_.Cell cell) => cell.result).toList();
