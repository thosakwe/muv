import 'package:source_span/source_span.dart';
import 'ast_node.dart';
import 'identifier.dart';
import 'token.dart';
import 'type.dart';

class ParameterList extends AstNode {
  final Token lParen, rParen;
  final List<Parameter> parameters;

  ParameterList(this.lParen, this.parameters, this.rParen);

  @override
  List<String> get comments => [];

  @override
  FileSpan get span {
    var s = lParen.span;
    if (parameters.isNotEmpty)
      s = s.expand(parameters.map((p) => p.span).reduce((a, b) => a.expand(b)));
    return s.expand(rParen.span);
  }
}

abstract class Parameter extends AstNode {}

// TODO: Add `as` to alias a parameter
class SimpleParameter extends Parameter {
  final Identifier name;
  final Token colon;
  final TypeNode type;

  SimpleParameter(this.name, this.colon, this.type);

  @override
  List<String> get comments => name.comments;

  @override
  FileSpan get span {
    if (colon == null) return name.span;
    return name.span.expand(colon.span).expand(type.span);
  }
}

class DestructuringParameter implements Parameter {
  final Token lCurly, rCurly;
  final List<SimpleParameter> properties;

  DestructuringParameter(this.lCurly, this.properties, this.rCurly);

  @override
  List<String> get comments => lCurly.comments;

  @override
  FileSpan get span {
    return properties
        .fold<FileSpan>(lCurly.span, (out, i) => out.expand(i.span))
        .expand(rCurly.span);
  }
}
