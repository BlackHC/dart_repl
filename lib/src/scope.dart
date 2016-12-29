// Copyright (c) 2016, Andreas 'blackhc' Kirsch. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';

@proxy
class Scope {
  final _scope = <Symbol, dynamic>{};

  Scope();

  Scope.predefined(Map<Symbol, dynamic> symbols) {
    _scope.addAll(symbols);
  }

  factory Scope.clone(Scope other) => new Scope.predefined(other._scope);

  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isGetter) {
      if (_scope.containsKey(invocation.memberName)) {
        return _scope[invocation.memberName];
      } else {
        return super.noSuchMethod(invocation);
      }
    } else if (invocation.isSetter) {
      final variable = MirrorSystem.getSymbol(
          MirrorSystem.getName(invocation.memberName).split('=').first);
      _scope[variable] = invocation.positionalArguments.first;
    } else if (invocation.isMethod) {
      return Function.apply(_scope[invocation.memberName] as Function,
          invocation.positionalArguments, invocation.namedArguments);
    } else {
      throw new UnsupportedError('Neither setter, nor getter, nor method!');
    }
  }
}
