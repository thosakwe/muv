import 'package:source_span/source_span.dart';

enum TokenType {
  // Symbols
  arrow,
  asterisk,
  colon,
  comma,
  dot,
  ellipsis,
  equals,
  minus,
  percent,
  plus,
  semi,
  slash,
  lBracket,
  rBracket,
  lCurly,
  rCurly,
  lParen,
  rParen,
  
  // Operators
  double_ampersand,
  double_asterisk,
  double_pipe,
  double_equals,
  shl,
  shr,
  lt,
  lte,
  gt,
  gte,
  plus_equals,
  minus_equals,
  double_asterisk_equals,
  asterisk_equals,
  slash_equals,
  percent_equals,
  shl_equals,
  shr_equals,
  triple_gt_equals,
  ampersand_equals,
  caret_equals,
  pipe_equals,

  // Keywords
  $as,
  $class,
  $const,
  $default,
  $export,
  from,
  function,
  $import,
  let,
  $new,
  $return,
  $var,

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