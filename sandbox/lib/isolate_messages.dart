// Copyright (c) 2016, Andreas 'blackhc' Kirsch. All rights reserved. Use of
// this source code is governed by a BSD-style license that can be found in the
// LICENSE file.

import 'package:dart_repl_sandbox/message_builder.dart';

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

final CellCommandConverters = new MessageConverters({
  ResetResult: ResetResult.fromRawMessage,
  CompleteResult: CompleteResult.fromRawMessage,
  SaveCell: SaveCell.fromRawMessage
});