// Copyright (c) 2016, Andreas 'blackhc' Kirsch. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:dart_repl/src/cell.dart';
import 'package:dart_repl/src/scope.dart';

abstract class SandboxInterface {
  Scope createScope();
  Scope getScope();
  Object getResult();
  void resetResult();
  void pushCell(Cell cell);
}