import 'dart:async';
import 'package:dart_repl/src/repl.dart';

// This is included here, so it can be customized with new imports.
import 'package:dart_repl/src/dynamic_environment.dart';

Future main() async {
  await repl();
}