// Copyright (c) 2016, Andreas 'blackhc' Kirsch. All rights reserved. Use of 
// this source code is governed by a BSD-style license that can be found in the 
// LICENSE file.

import 'package:dart_repl/src/scope.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    test('Scope works', () {
      final scope = new Scope.predefined(<Symbol, dynamic>{});
      scope.a = 1;
      expect(scope.a, 1);

      scope.f = (int a, {int field = 1}) => a + field;
      expect(scope.f(1), 2);
      expect(scope.f(1, field: 2), 3);
    });
  });
}
