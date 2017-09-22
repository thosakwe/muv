import 'package:string_scanner/string_scanner.dart';
import '../ast/ast.dart';
import 'error.dart';

final RegExp _whitespace = new RegExp(r'[ \n\r\t]+');
final RegExp _singleLineComment = new RegExp(r'//[^\n]*');
final RegExp _multiLineComment = new RegExp(r'/\*((.|\n)*)\*/');
final RegExp _string1 = new RegExp(
    r"'((\\(['\\/bfnrt]|(u[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])))|([^'\\]))*'");
final RegExp _string2 = new RegExp(
    r'"((\\(["\\/bfnrt]|(u[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])))|([^"\\]))*"');

final Map<Pattern, TokenType> _patterns = {
  // Symbols
  '=>': TokenType.arrow,
  '*': TokenType.asterisk,
  ':': TokenType.colon,
  ',': TokenType.comma,
  '.': TokenType.dot,
  '...': TokenType.ellipsis,
  '=': TokenType.equals,
  '-': TokenType.minus,
  '%': TokenType.percent,
  '+': TokenType.plus,
  '[': TokenType.lBracket,
  ']': TokenType.rBracket,
  '{': TokenType.lCurly,
  '}': TokenType.rCurly,
  '(': TokenType.lParen,
  ')': TokenType.rParen,
  ';': TokenType.semi,
  '/': TokenType.slash,

  // Operators
  '**': TokenType.double_asterisk,
  '<<': TokenType.shl,
  '>>': TokenType.shr,
  '<': TokenType.lt,
  '<=': TokenType.lte,
  '>': TokenType.gt,
  '>=': TokenType.gte,
  '==': TokenType.double_equals,
  '||': TokenType.double_pipe,
  '&&': TokenType.double_ampersand,

  '+=': TokenType.plus_equals,
  '-=': TokenType.minus_equals,
  '**=': TokenType.double_asterisk_equals,
  '*=': TokenType.asterisk_equals,
  '/=': TokenType.slash_equals,
  '%=': TokenType.percent_equals,
  '<<=': TokenType.shl_equals,
  '>>=': TokenType.shr_equals,
  '>>>=': TokenType.triple_gt_equals,
  '&=': TokenType.ampersand_equals,
  '^=': TokenType.caret_equals,
  '|=': TokenType.pipe_equals,

  // Keywords
  'as': TokenType.$as,
  'class': TokenType.$class,
  'const': TokenType.$const,
  'default': TokenType.$default,
  'export': TokenType.$export,
  'from': TokenType.from,
  'function': TokenType.function,
  'import': TokenType.$import,
  'let': TokenType.let,
  'new': TokenType.$new,
  'return': TokenType.$return,
  'var': TokenType.$var,

  // Expressions
  new RegExp(r'-?[0-9]+(\.[0-9]+)?([Ee][0-9]+)?'): TokenType.number,
  new RegExp(r'0x[A-Fa-f0-9]+'): TokenType.hex,
  _string1: TokenType.string,
  _string2: TokenType.string,
  new RegExp('[A-Za-z_\\\$][A-Za-z0-9_\\\$]*'): TokenType.id,
};

class Scanner {
  final SpanScanner _scanner;
  final List<MuvError> errors = [];
  final List<Token> tokens = [];

  Scanner(String text, sourceUrl)
      : _scanner = new SpanScanner(text, sourceUrl: sourceUrl);

  void scan() {
    LineScannerState errorStart;
    List<String> commentBuf = [];

    void flushError() {
      if (errorStart != null) {
        var errorSpan = _scanner.spanFrom(errorStart);
        errors.add(new MuvError(
          MuvErrorSeverity.ERROR,
          'Invalid syntax "${errorSpan.text}".',
          errorSpan,
        ));
        errorStart = null;
      }
    }

    _scanner.scan(_whitespace);

    while (!_scanner.isDone) {
      if (_scanner.scan(_singleLineComment)) {
        commentBuf.add(_scanner.lastMatch[0].substring(2).trim());
      } else if (_scanner.scan(_multiLineComment)) {
        commentBuf.add(_scanner.lastMatch[1].trim());
      } else {
        List<Token> potential = [];

        _patterns.forEach((pattern, type) {
          if (_scanner.matches(pattern)) {
            potential.add(new Token(type, _scanner.lastSpan));
          }
        });

        if (potential.isEmpty) {
          errorStart ??= _scanner.state;
          _scanner.readChar();
        } else {
          // Flush error buffer
          flushError();

          // Choose longest token
          potential.sort((a, b) {
            return b.span.text.length.compareTo(a.span.text.length);
          });

          // Flush comments
          var token = potential[0];
          tokens.add(token);
          token.comments.addAll(commentBuf);
          commentBuf.clear();
          _scanner.scan(token.span.text);
        }
      }

      if (_scanner.matches(_whitespace)) flushError();
      _scanner.scan(_whitespace);
    }

    flushError();
  }
}
