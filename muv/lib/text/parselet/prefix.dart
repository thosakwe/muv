part of muv.src.text.parselet;

const Map<TokenType, PrefixParselet> prefixParselets = const {
  TokenType.function: const BlockFunctionParselet(),
  TokenType.number: const NumberParselet(),
  TokenType.hex: const HexParselet(),
  TokenType.string: const StringParselet(),
  TokenType.lBracket: const ArrayParselet(),
  TokenType.id: const IdentifierParselet(),
};

class NumberParselet implements PrefixParselet {
  const NumberParselet();

  @override
  Expression parse(Parser parser, Token token) => new NumberLiteral(token);
}

class HexParselet implements PrefixParselet {
  const HexParselet();

  @override
  Expression parse(Parser parser, Token token) => new HexLiteral(token);
}

class StringParselet implements PrefixParselet {
  const StringParselet();

  @override
  Expression parse(Parser parser, Token token) =>
      new StringLiteral(token, StringLiteral.parseValue(token));
}

class ArrayParselet implements PrefixParselet {
  const ArrayParselet();

  @override
  Expression parse(Parser parser, Token token) {
    List<Expression> items = [];
    Expression item = parser.parseExpression(0);

    while (item != null) {
      items.add(item);
      if (!parser.next(TokenType.comma)) break;
      parser.skipExtraneous(TokenType.comma);
      item = parser.parseExpression(0);
    }

    if (!parser.next(TokenType.rBracket)) {
      var lastSpan = items.isEmpty ? null : items.last.span;
      lastSpan ??= token.span;
      parser.errors.add(new MuvError(MuvErrorSeverity.ERROR,
          'Missing "]" to terminate array literal.', lastSpan));
      return null;
    }

    return new Array(token, parser.current, items);
  }
}

class IdentifierParselet implements PrefixParselet {
  const IdentifierParselet();

  @override
  Expression parse(Parser parser, Token token) => new Identifier(token);
}

class BlockFunctionParselet implements PrefixParselet {
  const BlockFunctionParselet();

  @override
  Expression parse(Parser parser, Token token) {
    var name = parser.parseIdentifier();
    var parameterList = parser.parseParameterList();

    if (parameterList == null) {
      parser.errors.add(new MuvError(MuvErrorSeverity.ERROR,
          'Missing parameter list.', name?.span ?? token.span));
      return null;
    }

    TypeNode returnType;
    Token colon;

    if (parser.next(TokenType.colon)) {
      colon = parser.current;

      if ((returnType = parser.parseType()) == null) {
        parser.errors.add(new MuvError(MuvErrorSeverity.ERROR,
            'Expected a return type after ":".', colon.span));
        return null;
      }
    }

    if (!parser.next(TokenType.lCurly)) {
      parser.errors.add(new MuvError(MuvErrorSeverity.ERROR, 'Missing "{".',
          returnType?.span ?? parameterList?.span ?? name?.span ?? token.span));
      return null;
    }

    var lCurly = parser.current;
    var statements = <Statement>[];
    var statement = parser.parseStatement();

    while (statement != null) {
      statements.add(statement);
      parser.skipExtraneous(TokenType.semi);
      statement = parser.parseStatement();
    }

    if (!parser.next(TokenType.rCurly)) {
      var lastSpan = statements.isEmpty ? null : statements.last.span;
      lastSpan ??= lCurly.span ?? returnType?.span ?? parameterList?.span;
      parser.errors
          .add(new MuvError(MuvErrorSeverity.ERROR, 'Missing "}".', lastSpan));
      return null;
    }

    return new BlockFunction(token, name, parameterList, colon, returnType,
        lCurly, statements, parser.current);
  }
}
