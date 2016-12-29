import 'dart:collection';
import 'package:dart_repl/src/scope.dart';

class Cell {
  final Scope scope;
  final String input;
  final dynamic output;

  Cell(this.scope, this.input, this.output);

  @override
  String toString() =>
      {'scope': scope, 'input': input, 'output': output}.toString();
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
