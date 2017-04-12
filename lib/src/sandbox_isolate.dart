// Copyright (c) 2016, Andreas 'blackhc' Kirsch. All rights reserved. Use of
// this source code is governed by a BSD-style license that can be found in the
// LICENSE file.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:dart_repl/src/cell_generator.dart';
import 'package:dart_repl/src/package_utils.dart';
import 'package:dart_repl_sandbox/data_queue.dart';
import 'package:meta/meta.dart';
import 'package:package_resolver/package_resolver.dart';

class SandboxIsolate {
  final Isolate isolate;
  final SendPort sendPort;
  final DataQueue receiverQueue;
  final Future onExit;

  /// Path for all the top level cells.
  final TopLevelCellChain cellChain;

  SandboxIsolate(
      {@required this.isolate,
      @required this.sendPort,
      @required this.receiverQueue,
      @required this.onExit,
      @required this.cellChain});
}

/// Copies the template files, installs the adhoc imports, and returns
/// the running `SandboxIsolate`.
Future<SandboxIsolate> bootstrapIsolate(
    {String packageDir, List<String> imports = const <String>[]}) async {
  final packageConfig = await createSandboxPackageConfig(packageDir);
  final packageConfigUri = await packageConfig.packageConfigUri;

  final sandboxTemplateUri =
      await resolvePackageFile('package:dart_repl/src/template/sandbox.dart');
  final cellTemplateUri = await resolvePackageFile(
      'package:dart_repl/src/template/cell_template.dart');
  final baseIsolateUri =
      await resolvePackageFile('package:dart_repl/src/template/isolate.dart');

  final instanceDir = Directory.systemTemp.createTempSync('dart_repl');

  final isolateFile = new File(instanceDir.path + '/isolate.dart');

  // Copy isolate.dart.
  isolateFile.writeAsStringSync(await readUrl(baseIsolateUri));

  // Copy sandbox.dart and update imports in the
  // dynamic environment.
  final cellTemplate = new DartTemplate(await readUrl(cellTemplateUri));
  final headTemplate = new DartTemplate(await readUrl(sandboxTemplateUri));

  // Head template is imported by the isolate!
  final cellChain = new TopLevelCellChain(
      cellTemplate, headTemplate, 'sandbox.dart', instanceDir.path);

  // Create the first cell that imports everything specified on the command
  // line.
  // Need to export everything to make imports available later on,
  // too.
  final customImports = imports
      .map((import) => 'export \'${getImportPath(import, packageDir)}\';')
      .join('\n');
  // This is needed to create the head template, too!
  cellChain.addCell(customImports);

  // Setup communication channels.
  final receiverQueue = new DataQueue();
  final receivePort = new ReceivePort();
  receivePort.listen(receiverQueue.add);

  final onExitPort = new ReceivePort();
  final onErrorPort = new ReceivePort();
  onErrorPort.listen((dynamic error) {
    print(error);
  });

  final onExitCompleter = new Completer<Null>();
  onExitPort.listen((dynamic unused) {
    onExitPort.close();
    onErrorPort.close();
    onExitCompleter.complete();
    receivePort.close();
  });

  // TODO(blackhc): add onError listener!
  final isolate = await Isolate.spawnUri(
      isolateFile.uri, [], receivePort.sendPort,
      onExit: onExitPort.sendPort,
      onError: onErrorPort.sendPort,
      checked: true,
      packageConfig: packageConfigUri);

  final sendPort = await receiverQueue.receive() as SendPort;

  return new SandboxIsolate(
      isolate: isolate,
      receiverQueue: receiverQueue,
      sendPort: sendPort,
      onExit: onExitCompleter.future,
      cellChain: cellChain);
}

// TODO: add support for pub: that resolves a versioned package?
String getImportPath(String import, String packageDir) {
  if (import.startsWith('package:') || import.startsWith('dart:')) {
    return import;
  }
  return '$packageDir/$import';
}

Future<String> readUrl(Uri uri) async {
  if (uri.scheme == 'file') {
    return new File(uri.toFilePath()).readAsStringSync();
  }
  final request = await new HttpClient().getUrl(uri);
  final response = await request.close();
  final contentPieces = await response.transform(new Utf8Decoder()).toList();
  final content = contentPieces.join();
  return content;
}
