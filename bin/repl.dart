// Copyright (c) 2016, Andreas 'blackhc' Kirsch. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:args/args.dart';
import 'package:dart_repl/dart_repl.dart';
import 'package:dart_repl/src/repl_runner.dart' as repl_runner;

void main(List<String> args) {
  var parser = new ArgParser();
  parser.addOption('adhoc-import', allowMultiple: true);
  parser.addOption('package-dir', allowMultiple: false, defaultsTo: Directory.current.absolute.path);
  var results = parser.parse(args);
  if (results['adhoc-import'].isEmpty) {
    repl_runner.main();
  } else {
    // ignore: argument_type_not_assignable
    customRepl(results['package-dir'], results['adhoc-import']);
  }
}