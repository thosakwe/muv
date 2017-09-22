part of muv.src.text.parselet;

const Map<TokenType, InfixParselet> infixParselets = const {
  TokenType.lParen: const CallParselet(),
  TokenType.dot: const MemberParselet(),
  TokenType.double_asterisk: const BinaryParselet(15),
  TokenType.asterisk: const BinaryParselet(14),
  TokenType.slash: const BinaryParselet(14),
  TokenType.percent: const BinaryParselet(14),
  TokenType.plus: const BinaryParselet(13),
  TokenType.minus: const BinaryParselet(13),
  TokenType.equals: const BinaryParselet(3),
  TokenType.plus_equals: const BinaryParselet(3),
  TokenType.minus_equals: const BinaryParselet(3),
  TokenType.double_asterisk_equals: const BinaryParselet(3),
  TokenType.asterisk_equals: const BinaryParselet(3),
  TokenType.slash_equals: const BinaryParselet(3),
  TokenType.percent_equals: const BinaryParselet(3),
  TokenType.shl_equals: const BinaryParselet(3),
  TokenType.shr_equals: const BinaryParselet(3),
  TokenType.triple_gt_equals: const BinaryParselet(3),
  TokenType.ampersand_equals: const BinaryParselet(3),
  TokenType.caret_equals: const BinaryParselet(3),
  TokenType.pipe_equals: const BinaryParselet(3),
};

class BinaryParselet implements InfixParselet {
  final int precedence;

  const BinaryParselet(this.precedence);

  @override
  Expression parse(Parser parser, Expression left, Token token) {
    var right = parser.parseExpression(precedence);

    if (right == null) {
      parser.errors.add(new MuvError(MuvErrorSeverity.ERROR, 'Missing expression after operator "".', token.span));
      return null;
    }

    return new BinaryExpression(left, token, right);
  }
}

class CallParselet implements InfixParselet {
  const CallParselet();

  @override
  int get precedence => 19;

  @override
  Expression parse(Parser parser, Expression left, Token token) {
    List<Expression> arguments = [];
    Expression argument = parser.parseExpression(0);

    while (argument != null) {
      arguments.add(argument);
      if (!parser.next(TokenType.comma)) break;
      parser.skipExtraneous(TokenType.comma);
      argument = parser.parseExpression(0);
    }

    if (!parser.next(TokenType.rParen)) {
      var lastSpan = arguments.isEmpty ? null : arguments.last.span;
      lastSpan ??= token.span;
      parser.errors.add(new MuvError(MuvErrorSeverity.ERROR,
          'Missing ")" after argument list.', lastSpan));
      return null;
    }

    return new Call(left, token, parser.current, arguments);
  }
}

class MemberParselet implements InfixParselet {
  const MemberParselet();

  @override
  int get precedence => 19;

  @override
  Expression parse(Parser parser, Expression left, Token token) {
    var name = parser.parseIdentifier();

    if (name == null) {
      parser.errors.add(new MuvError(MuvErrorSeverity.ERROR,
          'Expected the name of a property following "."', token.span));
      return null;
    }

    return new MemberExpression(left, token, name);
  }
}
