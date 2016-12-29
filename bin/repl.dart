// Copyright (c) 2016, Andreas 'blackhc' Kirsch. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'package:args/args.dart';
import 'package:dart_repl/dart_repl.dart';
import 'package:dart_repl/src/repl_runner.dart' as repl_runner;

Future main(List<String> args) async {
  var parser = new ArgParser();
  parser.addFlag('help');
  parser.addOption('adhoc-import', allowMultiple: true);
  parser.addOption('package-dir', allowMultiple: false, defaultsTo: Directory.current.absolute.path);
  var results = parser.parse(args);

  if (results['help'] as bool) {
    print(parser.usage);
    return;
  }

  final adhocImports = results['adhoc-import'] as List<String>;
  final packageDir = results['package-dir'] as String;
  if (adhocImports.isEmpty) {
    await repl_runner.main();
  } else {
    // ignore: argument_type_not_assignable
    await customRepl(packageDir, adhocImports);
  }
}