// Copyright (c) 2016, Andreas 'blackhc' Kirsch. All rights reserved. Use of
// this source code is governed by a BSD-style license that can be found in the
// LICENSE file.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:dart_repl/src/cell_generator.dart';
import 'package:dart_repl_sandbox/message_queue.dart';
import 'package:meta/meta.dart';
import 'package:package_resolver/package_resolver.dart';

class SandboxIsolate {
  final Isolate isolate;
  final SendPort sendPort;
  final MessageQueue receiverQueue;
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
  final packageConfig = await createPackageConfig(packageDir);
  final packageConfigUri = await packageConfig.packageConfigUri;

  final baseDynamicEnvironmentUri = await resolvePackageFile(
      'package:dart_repl/src/template/sandbox.dart');
  final baseCellTemplateUri = await resolvePackageFile(
      'package:dart_repl/src/template/cell_template.dart');
  final baseIsolateUri =
      await resolvePackageFile('package:dart_repl/src/template/isolate.dart');

  final instanceDir = Directory.systemTemp.createTempSync('dart_repl');

  final isolateFile = new File(instanceDir.path + '/isolate.dart');

  // Copy isolate.dart.
  isolateFile.writeAsStringSync(await readUrl(baseIsolateUri));

  // Copy sandbox.dart and update imports in the
  // dynamic environment.
  final cellTemplate = new DartTemplate(await readUrl(baseCellTemplateUri));
  final headTemplate =
      new DartTemplate(await readUrl(baseDynamicEnvironmentUri));

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
  final receiverQueue = new MessageQueue();
  final receivePort = new ReceivePort();
  receivePort.listen(receiverQueue.addMessage);

  final onExitPort = new ReceivePort();
  final onExitCompleter = new Completer<Null>();
  onExitPort.listen((dynamic unused) {
    onExitPort.close();
    onExitCompleter.complete();
    receivePort.close();
  });

  // TODO(blackhc): add onError listener!
  final isolate = await Isolate.spawnUri(
      isolateFile.uri, [], receivePort.sendPort,
      onExit: onExitPort.sendPort,
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

Future<PackageResolver> createPackageConfig(String otherPackageDir) async {
  // TODO: better error handling when 'pub get' wasn't called on either package dir!!
  final otherConfig = await loadPackageConfigMap(otherPackageDir);
  // Safe copy.
  final config = new Map<String, Uri>.from(otherConfig);
  config.addAll(otherConfig);
  // We only need to add a dependency on the dart_repl_sandbox virtual package.
  final thisPackageUri = await getThisPackageUri();
  final sandboxPackageUri =
      thisPackageUri.replace(path: '${thisPackageUri.path}/../sandbox/lib');
  config['dart_repl_sandbox'] = sandboxPackageUri;
  return new PackageResolver.config(config);
}

Future<Map<String, Uri>> loadPackageConfigMap(String packageDir) async {
  if (packageDir != null) {
    // Only try to load it if the .packages file exists.
    final packagesFilePath = packageDir + '/.packages';
    if (new File(packagesFilePath).existsSync()) {
      return (await SyncPackageResolver.loadConfig(packagesFilePath))
          .packageConfigMap;
    }
  }
  return <String, Uri>{};
}

Future<Uri> getThisPackageUri() async {
  final entryLibrary =
      await resolvePackageFile('package:dart_repl/dart_repl.dart');
  final thisPackage = entryLibrary.replace(
      pathSegments: entryLibrary.pathSegments
          .sublist(0, entryLibrary.pathSegments.length - 1));
  return thisPackage;
}

Future<Uri> resolvePackageFile(String packagePath) async {
  return await Isolate.resolvePackageUri(Uri.parse(packagePath));
}

// TODO: add support for pub: that resolves a versioned package?
String getImportPath(String import, String packageDir) {
  if (import.startsWith('package:') || import.startsWith('dart:')) {
    return import;
  }
  return '$packageDir/$import';
}
