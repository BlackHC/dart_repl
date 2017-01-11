// Copyright (c) 2016, Andreas 'blackhc' Kirsch. All rights reserved. Use of 
// this source code is governed by a BSD-style license that can be found in the 
// LICENSE file.
import 'package:dart_repl/src/cell.dart' as cell;

Object result__;

final Cell = <cell.Cell>[];
final Out = new cell.CellAccessor<dynamic>(Cell, (cell) => cell.output);
final In = new cell.CellAccessor<String>(Cell, (cell) => cell.input);

dynamic get $ => Out.last;
dynamic get $$ => Out[Out.length - 2];
dynamic get $$$ => Out[Out.length - 2];
