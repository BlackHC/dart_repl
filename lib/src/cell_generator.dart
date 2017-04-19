// Copyright (c) 2017, Andreas 'blackhc' Kirsch. All rights reserved. Use of
// this source code is governed by a BSD-style license that can be found in the
// LICENSE file.
import 'dart:io';

class DartTemplate {
  final String content;

  DartTemplate(this.content);

  void instantiate(String targetPath,
      {String source, String library, String imports}) {
    final instanceSource = content
        .replaceAll('/*{SOURCE}*/', source ?? '')
        .replaceAll('/*{IMPORTS}*/', imports ?? '')
        .replaceAll('/*{LIBRARY}*/', library ?? '');
    new File(targetPath).writeAsStringSync(instanceSource);
    //print('wrote $targetPath:\n$instanceSource');
  }
}

/// Keeps a chain of temporary cell files that import and re-export each other.
/// This allows us to create top-level cells that contains classes and other
/// top-level decls that can shadow each other.
class TopLevelCellChain {
  final DartTemplate cellTemplate;
  final String headName;
  final String basePath;

  int _currentCellIndex = 0;

  TopLevelCellChain(this.cellTemplate, this.headName, this.basePath);

  String get currentCellPath => '$basePath/$currentCellName';
  String get currentCellName => 'cell${_currentCellIndex}.dart';
  String get headPath => '$basePath/$headName';

  void addCell(String source) {
    // Import and export the previous cell.
    final imports = _currentCellIndex > 0
        ? '''
// Import the previous cell and export it to make its symbols available to the
// next cell.
import '$currentCellName';
export '$currentCellName';
'''
        : '';

    _currentCellIndex++;
    cellTemplate.instantiate(currentCellPath, imports: imports, source: source);

    // Update the sandbox.
    refreshSandboxLibrary();
  }

  void refreshSandboxLibrary() {
    var libraryStatement = '''
/// This library name is needed to find the library using reflection.
library sandbox;
''';

    cellTemplate.instantiate(headPath,
        imports: _currentCellIndex > 0 ? 'import \'$currentCellName\';' : '',
        library: libraryStatement);
  }

  void undoCell() {
    if (_currentCellIndex > 0) {
      _currentCellIndex--;
    }
    refreshSandboxLibrary();
  }
}
