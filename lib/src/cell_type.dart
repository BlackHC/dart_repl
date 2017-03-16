// Copyright (c) 2016, Andreas 'blackhc' Kirsch. All rights reserved. Use of
// this source code is governed by a BSD-style license that can be found in the
// LICENSE file.
import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/parser.dart';

enum CellType { UNKNOWN, TOP_LEVEL, STATEMENTS, AWAIT_EXPRESSION, EXPRESSION }

typedef T ParserClosure<T>(Parser parser, Token token);

bool _tryParse<T>(String code, ParserClosure<T> parse) {
  final reader = new CharSequenceReader(code);
  final errorListener = new BooleanErrorListener();
  final scanner = new Scanner(null, reader, errorListener);
  final token = scanner.tokenize();
  final parser = new Parser(null, errorListener);
  final node = parse(parser, token) as AstNode;

  return !errorListener.errorReported &&
      node != null &&
      node.endToken.next.type == TokenType.EOF;
}

bool isExpression(String code) =>
    _tryParse(
        code, (Parser parser, Token token) => parser.parseExpression(token));

bool isStatements(String code) =>
    _tryParse(code, (Parser parser, Token token) {
      final statements = parser.parseStatements(token);
      if (statements.isEmpty) {
        return null;
      }
      return statements.last;
    });

bool isTopLevel(String code) =>
    _tryParse(code,
        (Parser parser, Token token) => parser.parseCompilationUnit(token));

CellType determineCellType(String code) {
  if (isTopLevel(code)) {
    return CellType.TOP_LEVEL;
  } else if (isStatements(code)) {
    return CellType.STATEMENTS;
  } else if (isExpression(code)) {
    return CellType.EXPRESSION;
  } else if (isExpression("(() async => $code)()")) {
    return CellType.AWAIT_EXPRESSION;
  }
  return CellType.UNKNOWN;
}
