// Copyright (c) 2016, Andreas 'blackhc' Kirsch. All rights reserved. Use of
// this source code is governed by a BSD-style license that can be found in the
// LICENSE file.
import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:isolate';

import 'package:package_resolver/package_resolver.dart';

/// Simple queue of future messages.
///
/// Every time I try to use Streams, I feel stupid :( So let's not do that.
class MessageQueue {
  final messageQueue = new Queue<Object>();
  final receiverQueue = new Queue<Completer<Object>>();

  void addMessage(Object message) {
    if (receiverQueue.isNotEmpty) {
      final completer = receiverQueue.removeFirst();
      completer.complete(message);
      return;
    }
    messageQueue.addLast(message);
  }

  Future<Object> receive() async {
    if (messageQueue.isNotEmpty) {
      return messageQueue.removeFirst();
    }
    final completer = new Completer<Object>();
    receiverQueue.addLast(completer);
    return completer.future;
  }
}

class SandboxIsolate {
  final Isolate isolate;
  final SendPort sendPort;
  final MessageQueue receiverQueue;
  final Future onExit;

  SandboxIsolate(
      {this.isolate, this.sendPort, this.receiverQueue, this.onExit});
}

/// Copies the template files, installs the adhoc imports, and returns
/// the running `SandboxIsolate`.
Future<SandboxIsolate> bootstrapIsolate(
    {String packageDir, List<String> imports = const <String>[]}) async {
  final mergedPackageConfig = await mergePackageConfigs(packageDir);
  final mergedPackageConfigUri = await mergedPackageConfig.packageConfigUri;

  final baseDynamicEnvironmentUri = await resolvePackageFile(
      'package:dart_repl/src/template/dynamic_environment.dart');
  final baseIsolateUri =
      await resolvePackageFile('package:dart_repl/src/template/isolate.dart');

  final instanceDir = Directory.systemTemp.createTempSync('custom_dart_repl');
  final dynamicEnvironmentFile = new File.fromUri(baseDynamicEnvironmentUri)
      .copySync(instanceDir.path + '/dynamic_environment.dart');
  final isolateFile = new File.fromUri(baseIsolateUri)
      .copySync(instanceDir.path + '/isolate.dart');

  // Copy isolate.dart.
  isolateFile.writeAsStringSync(isolateFile.readAsStringSync());

  // Update imports in the dynamic environment.
  final customImports = imports
      .map((import) => 'import \'${getImportPath(import, packageDir)}\';')
      .join('\n');
  dynamicEnvironmentFile.writeAsStringSync(dynamicEnvironmentFile
      .readAsStringSync()
      .replaceAll('/*\${IMPORTS}*/', customImports));

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

  final isolate = await Isolate.spawnUri(
      isolateFile.uri, [], receivePort.sendPort,
      onExit: onExitPort.sendPort,
      checked: true,
      packageConfig: mergedPackageConfigUri);

  final sendPort = await receiverQueue.receive() as SendPort;

  return new SandboxIsolate(
      isolate: isolate,
      receiverQueue: receiverQueue,
      sendPort: sendPort,
      onExit: onExitCompleter.future);
}

Future<PackageResolver> mergePackageConfigs(String otherPackageRoot) async {
  final currentConfig = await PackageResolver.current.packageConfigMap;
  final otherConfig = otherPackageRoot != null
      ? (await SyncPackageResolver.loadConfig(otherPackageRoot + '/.packages'))
          .packageConfigMap
      : <String, Uri>{};
  final config = <String, Uri>{};
  // We only need the dart_repl_sandbox package.
  config['dart_repl_sandbox'] = currentConfig['dart_repl_sandbox'];
  config.addAll(otherConfig);
  return new PackageResolver.config(config);
}

Future<Uri> resolvePackageFile(String packagePath) async {
  return await Isolate.resolvePackageUri(Uri.parse(packagePath));
}

String getImportPath(String import, String packageDir) {
  if (import.startsWith('package:') || import.startsWith('dart:')) {
    return import;
  }
  return '$packageDir/$import';
}
