import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/parser.dart';

bool _tryParse(String code, Function parse) {
  final reader = new CharSequenceReader(code);
  final errorListener = new BooleanErrorListener();
  final scanner = new Scanner(null, reader, errorListener);
  final token = scanner.tokenize();
  final parser = new Parser(null, errorListener);
  final node = parse(parser, token) as AstNode;

  return !errorListener.errorReported &&
      node.endToken.next.type == TokenType.EOF;
}

bool isExpression(String code) => _tryParse(
    code, (Parser parser, Token token) => parser.parseExpression(token));

bool isStatements(String code) => _tryParse(code, (Parser parser, Token token) {
      final statements = parser.parseStatements(token);
      if (statements.isEmpty) {
        return null;
      }
      return statements.last;
    });
