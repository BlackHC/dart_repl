import 'dart:async';

import 'dart:io';
import 'dart:isolate';
import 'package:package_resolver/package_resolver.dart';

Future<PackageResolver> addPackage(
    String packageUri, String newPackage, String newPath) async {
  final oldConfig =
      (await SyncPackageResolver.loadConfig(packageUri)).packageConfigMap;
  final config = new Map<String, Uri>.from(oldConfig);
  config[newPackage] = new Uri.file(newPath);
  return new PackageResolver.config(config);
}

Future<PackageResolver> createSandboxPackageConfig(
    String otherPackageDir) async {
  // TODO: error handling when 'pub get' wasn't called on either package dir!
  final otherConfig = await loadPackageConfigMap(otherPackageDir);
  // Safe copy.
  final config = new Map<String, Uri>.from(otherConfig);
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
