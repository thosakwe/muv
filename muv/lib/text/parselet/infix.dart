part of muv.src.text.parselet;

const Map<TokenType, InfixParselet> infixParselets = const {
  TokenType.lParen: const CallParselet(),
  TokenType.dot: const MemberParselet(),
};

class CallParselet implements InfixParselet {
  const CallParselet();

  @override
  int get precedence => 2;

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
  int get precedence => 2;

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
