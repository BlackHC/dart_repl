// Copyright (c) 2016, Andreas 'blackhc' Kirsch. All rights reserved. Use of 
// this source code is governed by a BSD-style license that can be found in the 
// LICENSE file.
import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:package_resolver/package_resolver.dart';

Future<Uri> resolvePackageFile(String packagePath) async {
  return await Isolate.resolvePackageUri(Uri.parse(packagePath));
}

String getImportPath(String import, String packageDir) {
  if (import.startsWith('package:') || import.startsWith('dart:')) {
    return import;
  }
  return '$packageDir/$import';
}

Future customRepl(String packageDir, List<String> imports) async {
  final mergedPackageConfig = await mergePackageConfigs(packageDir);
  final mergedPackageConfigUri = await mergedPackageConfig.packageConfigUri;

  final baseDynamicEnvironmentUri = await resolvePackageFile(
      'package:dart_repl/src/dynamic_environment.dart');
  final baseReplRunnerUri =
      await resolvePackageFile('package:dart_repl/src/repl_runner.dart');

  final instanceDir = Directory.systemTemp.createTempSync('custom_dart_repl');
  final dynamicEnvironmentFile = new File.fromUri(baseDynamicEnvironmentUri)
      .copySync(instanceDir.path + '/dynamic_environment.dart');
  final replRunnerFile = new File.fromUri(baseReplRunnerUri)
      .copySync(instanceDir.path + '/repl_runner.dart');

  // Update import in the custom repl runner.
  replRunnerFile.writeAsStringSync(replRunnerFile.readAsStringSync().replaceAll(
      'package:dart_repl/src/dynamic_environment.dart',
      dynamicEnvironmentFile.absolute.path));

  // Update imports in the dynamic environment.
  final customImports = imports
      .map((import) => 'import \'${getImportPath(import, packageDir)}\';')
      .join('\n');
  dynamicEnvironmentFile.writeAsStringSync(dynamicEnvironmentFile
      .readAsStringSync()
      .replaceAll('/*\${IMPORTS}*/', customImports));

  final onExitPort = new ReceivePort();
  final onExitCompleter = new Completer<Null>();
  onExitPort.listen((dynamic unused) {
    onExitPort.close();
    onExitCompleter.complete();
  });

  await Isolate.spawnUri(replRunnerFile.uri, [], null,
      onExit: onExitPort.sendPort,
      checked: true,
      packageConfig: mergedPackageConfigUri);

  await onExitCompleter.future;
}

Future<PackageResolver> mergePackageConfigs(String otherPackageRoot) async {
  final currentConfig = await PackageResolver.current.packageConfigMap;
  final otherConfig =
      (await SyncPackageResolver.loadConfig(otherPackageRoot + '/.packages'))
          .packageConfigMap;
  // We do something horrible here: We simply overwrite the current config with
  // the other. Hoping it will still work..
  final config = <String, Uri>{};
  config.addAll(currentConfig);
  config.addAll(otherConfig);
  return new PackageResolver.config(config);
}

Future main() async {
  await customRepl(
      '/home/blackhc/git/built_collection.dart', ['lib/built_collection.dart']);
}
