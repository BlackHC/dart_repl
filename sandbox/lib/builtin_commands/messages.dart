// Copyright (c) 2017, Andreas 'blackhc' Kirsch. All rights reserved. Use of
// this source code is governed by a BSD-style license that can be found in the
// LICENSE file.

import 'package:dart_repl_sandbox/message_converter.dart';

final SandboxRequestQueueConverters = new MessageConverter({
  ImportLibraryRequest: ImportLibraryRequest.fromRawMessage,
  LoadPackageRequest: LoadPackageRequest.fromRawMessage,
  ExitRequest: ExitRequest.fromRawMessage
});

class ImportLibraryRequest extends Message<ImportLibraryRequest> {
  final String libraryPath;

  ImportLibraryRequest(this.libraryPath);

  static ImportLibraryRequest fromRawMessage(Object simpleFormat) =>
      new ImportLibraryRequest(simpleFormat as String);

  @override
  Object toRawData() => libraryPath;
}

class LoadPackageRequest extends Message<LoadPackageRequest> {
  final String packageName;
  final String packageConfigUri;

  LoadPackageRequest(this.packageName, this.packageConfigUri);

  static LoadPackageRequest fromRawMessage(Object simpleFormat) {
    final dict = simpleFormat as Map<String, String>;
    return new LoadPackageRequest(dict['name'], dict['configUri']);
  }

  @override
  Object toRawData() => {'name': packageName, 'configUri': packageConfigUri};
}

class ExitRequest extends Message<ExitRequest> {
  static ExitRequest fromRawMessage(Object simpleFormat) => new ExitRequest();
}
