import '../ast/ast.dart';
import '../text/text.dart';
import 'parselet/parselet.dart';
import 'scanner.dart';

class Parser {
  final List<MuvError> errors = [];
  final Scanner scanner;

  Token _current;
  int _index = -1;

  Parser(this.scanner);

  Token get current => _current;

  int _nextPrecedence() {
    var tok = peek();
    if (tok == null) return 0;

    var parser = infixParselets[tok.type];
    return parser?.precedence ?? 0;
  }

  bool next(TokenType type) {
    if (_index >= scanner.tokens.length - 1) return false;
    var peek = scanner.tokens[_index + 1];

    if (peek.type != type) return false;

    _current = peek;
    _index++;
    return true;
  }

  Token peek() {
    if (_index >= scanner.tokens.length - 1) return null;
    return scanner.tokens[_index + 1];
  }

  Token maybe(TokenType type) => next(type) ? _current : null;

  void skipExtraneous(TokenType type) {
    while (next(type)) {
      // Skip...
    }
  }

  Program parseProgram() {
    var topLevelDeclarations = <TopLevel>[];
    var topLevel = parseTopLevel();

    while (topLevel != null) {
      topLevelDeclarations.add(topLevel);
      topLevel = parseTopLevel();
    }

    return new Program(topLevelDeclarations);
  }

  // TODO: Imports, etc.
  TopLevel parseTopLevel() => parseTopLevelStatement();

  TopLevelStatement parseTopLevelStatement() {
    var statement = parseStatement();
    return statement != null ? new TopLevelStatement(statement) : null;
  }

  // TODO: Other statements
  Statement parseStatement() =>
      parseVariableDeclarationStatement() ?? parseExpressionStatement();

  VariableDeclarationStatement parseVariableDeclarationStatement() {
    Token $const, let;
    if (next(TokenType.$const))
      $const = _current;
    else if (next(TokenType.let))
      let = _current;
    else
      return null;

    var variableDeclarations = <VariableDeclaration>[];
    var variableDeclaration = parseVariableDeclaration();

    while (variableDeclaration != null) {
      variableDeclarations.add(variableDeclaration);
      if (!next(TokenType.comma)) break;
      skipExtraneous(TokenType.comma);
      variableDeclaration = parseVariableDeclaration();
    }

    var semi = maybe(TokenType.semi);
    skipExtraneous(TokenType.semi);

    return new VariableDeclarationStatement(
        $const, let, variableDeclarations, semi);
  }

  VariableDeclaration parseVariableDeclaration() {
    var name = parseIdentifier();
    if (name == null) return null;

    if (!next(TokenType.equals))
      return new VariableDeclaration(name, null, null);

    var equals = _current;
    var expression = parseExpression(0);

    if (expression == null) {
      errors.add(new MuvError(MuvErrorSeverity.ERROR,
          'Missing value for variable "${name.name}".', equals.span));
      return null;
    }

    return new VariableDeclaration(name, equals, expression);
  }

  ExpressionStatement parseExpressionStatement() {
    var expression = parseExpression(0);
    return expression != null
        ? new ExpressionStatement(expression, maybe(TokenType.semi))
        : null;
  }

  ParameterList parseParameterList() {
    if (!next(TokenType.lParen)) return null;
    var lParen = _current;
    List<Parameter> parameters = [];
    Parameter parameter = parseParameter();

    while (parameter != null) {
      parameters.add(parameter);
      if (!next(TokenType.comma)) break;
      skipExtraneous(TokenType.comma);
      parameter = parseParameter();
    }

    if (!next(TokenType.rParen)) {
      var lastSpan = parameters.isEmpty ? null : parameters.last.span;
      lastSpan ??= lParen.span;
      errors
          .add(new MuvError(MuvErrorSeverity.ERROR, 'Missing ")".', lastSpan));
      return null;
    }

    return new ParameterList(lParen, parameters, _current);
  }

  Parameter parseParameter() {
    var name = parseIdentifier();
    if (name == null) return null;

    Token colon;
    TypeNode type;

    if (next(TokenType.colon)) {
      colon = _current;

      if ((type = parseType()) == null) {
        errors.add(new MuvError(
            MuvErrorSeverity.ERROR,
            'Missing type annotation for parameter "${name.name}".',
            colon.span));
        return null;
      }
    }

    return new Parameter(name, colon, type);
  }

  // TODO: Other types?
  TypeNode parseType() => parseSimpleType();

  SimpleType parseSimpleType() {
    var name = parseIdentifier();
    return name != null ? new SimpleType(name) : null;
  }

  Identifier parseIdentifier() =>
      next(TokenType.id) ? new Identifier(_current) : null;

  Expression parseExpression(int precedence) {
    // Only consume a token if it could potentially be a prefix parselet

    for (var type in prefixParselets.keys) {
      if (next(type)) {
        var left = prefixParselets[type].parse(this, _current);

        while (precedence < _nextPrecedence()) {
          _current = scanner.tokens[++_index];
          var infix = infixParselets[_current.type];
          left = infix.parse(this, left, _current);
        }

        return left;
      }
    }

    // Nothing was parsed; return null.
    return null;
  }
}
