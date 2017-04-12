// Copyright (c) 2017, Andreas 'blackhc' Kirsch. All rights reserved. Use of
// this source code is governed by a BSD-style license that can be found in the
// LICENSE file.
import 'dart:io';

class DartTemplate {
  final String content;

  DartTemplate(this.content);

  void instantiate(String targetPath, [String source, String libraryHeader]) {
    final instanceSource = content.replaceAll('/*{SOURCE}*/', source ?? '');
    new File(targetPath).writeAsStringSync(instanceSource);
    //print('wrote $targetPath:\n$instanceSource');
  }
}

/// Keeps a chain of temporary cell files that import and re-export each other.
/// This allows us to create top-level cells that contains classes and other
/// top-level decls that can shadow each other.
class TopLevelCellChain {
  final DartTemplate cellTemplate;
  final DartTemplate headTemplate;
  final String headName;
  final String basePath;

  int _currentCellIndex = 0;

  TopLevelCellChain(
      this.cellTemplate, this.headTemplate, this.headName, this.basePath);

  String get currentCellPath => '$basePath/$currentCellName';
  String get currentCellName => 'cell${_currentCellIndex}.dart';
  String get headPath => '$basePath/$headName';

  void addCell(String source) {
    final cellSource = _currentCellIndex > 0
        ? '''
// Import the previous cell and make its symbols available to the next
// cell.
import '$currentCellName';
export '$currentCellName';

// __env is always available.
import 'package:dart_repl_sandbox/cell_environment.dart' as __env;
// Provide builtin commands like `exit` or `import`.
import 'package:dart_repl_sandbox/builtin_commands/api.dart' as __api;

$source
'''
        : source;

    _currentCellIndex++;
    cellTemplate.instantiate(currentCellPath, cellSource);
    headTemplate.instantiate(headPath, 'import \'$currentCellName\';');
  }

  void undoCell() {
    if (_currentCellIndex > 0) {
      _currentCellIndex--;
      headTemplate.instantiate(headPath, 'import \'$currentCellName\';');
    } else {
      headTemplate.instantiate(headPath);
    }
  }
}
