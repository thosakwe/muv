import 'package:source_span/source_span.dart';

enum TokenType {
  // Symbols
  arrow,
  colon,
  comma,
  dot,
  ellipsis,
  equals,
  semi,
  lBracket,
  rBracket,
  lCurly,
  rCurly,
  lParen,
  rParen,

  // Keywords
  $class,
  $const,
  function,
  let,
  $return,

  // Expressions
  number,
  hex,
  string,
  id,
}

class Token {
  final List<String> comments = [];
  final TokenType type;
  final FileSpan span;

  Token(this.type, this.span);
}