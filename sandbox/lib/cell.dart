// Copyright (c) 2016, Andreas 'blackhc' Kirsch. All rights reserved. Use of
// this source code is governed by a BSD-style license that can be found in the
// LICENSE file.
import 'dart:collection';

import 'scope.dart';

// TODO: store the current cell name, too, to make it possible to reimport it.
// (In order to access the namespace...)
class Cell {
  final String input;
  final dynamic output;

  Cell(this.input, this.output);

  @override
  String toString() =>
      <String, dynamic>{'input': input, 'output': output}.toString();
}

typedef T Accessor<T>(Cell cell);

class CellAccessor<T> extends ListMixin<T> {
  final List<Cell> _cells;
  final Accessor<T> _accessor;

  CellAccessor(this._cells, this._accessor);

  @override
  int get length => _cells.length;

  @override
  T operator [](int index) => _accessor(_cells[index]);

  @override
  void operator []=(int index, T value) =>
      throw new UnsupportedError('Out is readonly!');

  @override
  void set length(int newLength) =>
      throw new UnsupportedError('Out is readonly!');
}
