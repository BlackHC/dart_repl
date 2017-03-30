// Copyright (c) 2016, Andreas 'blackhc' Kirsch. All rights reserved. Use of
// this source code is governed by a BSD-style license that can be found in the
// LICENSE file.

import 'dart:isolate';
import 'package:dart_repl_sandbox/message_converter.dart';

class RegisterRequestPort extends Message<RegisterRequestPort> {
  final SendPort sendPort;

  RegisterRequestPort(this.sendPort);

  static RegisterRequestPort fromRawMessage(Object simpleFormat) =>
      new RegisterRequestPort(simpleFormat as SendPort);

  @override
  Object toRawData() => sendPort;
}

class ResetResult extends Message<ResetResult> {
  static ResetResult fromRawMessage(Object simpleFormat) => new ResetResult();
}

class CompleteResult extends Message<CompleteResult> {
  static CompleteResult fromRawMessage(Object simpleFormat) =>
      new CompleteResult();
}

class SaveCell extends Message<SaveCell> {
  final String input;

  SaveCell(this.input);

  static SaveCell fromRawMessage(Object simpleFormat) =>
      new SaveCell(simpleFormat as String);

  @override
  Object toRawData() => input;
}

final CellCommandConverters = new MessageConverter({
  RegisterRequestPort: RegisterRequestPort.fromRawMessage,
  ResetResult: ResetResult.fromRawMessage,
  CompleteResult: CompleteResult.fromRawMessage,
  SaveCell: SaveCell.fromRawMessage
});

class CellResult extends Message<CellResult> {
  final String result;

  CellResult(this.result);

  static CellResult fromRawMessage(Object simpleFormat) =>
      new CellResult(simpleFormat as String);

  @override
  Object toRawData() => result;
}

final CellReplyConverters =
    new MessageConverter({CellResult: CellResult.fromRawMessage});

class ImportLibraryRequest extends Message<ImportLibraryRequest> {
  final String libraryPath;

  ImportLibraryRequest(this.libraryPath);

  static ImportLibraryRequest fromRawMessage(Object simpleFormat) =>
      new ImportLibraryRequest(simpleFormat as String);

  @override
  Object toRawData() => libraryPath;
}

final SandboxRequestQueueConverters = new MessageConverter(
    {ImportLibraryRequest: ImportLibraryRequest.fromRawMessage});
