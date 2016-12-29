import 'package:dart_repl/src/scope.dart';

class Cell {
  final Scope scope;
  final String code;
  final dynamic result;

  Cell(this.scope, this.code, this.result);

  String toString() =>
      {'scope': scope, 'code': code, 'result': result}.toString();
}
