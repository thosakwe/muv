import 'package:source_span/source_span.dart';

enum TokenType {
  // Symbols
  arrow,
  $as,
  asterisk,
  colon,
  comma,
  dot,
  ellipsis,
  equals,
  from,
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
  $import,
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