import 'package:source_span/source_span.dart';
import 'expression.dart';
import 'identifier.dart';
import 'token.dart';

class MemberExpression extends Expression {
  final Expression expression;
  final Token dot;
  final Identifier name;

  MemberExpression(this.expression, this.dot, this.name);

  @override
  List<String> get comments => expression.comments;

  @override
  FileSpan get span => expression.span.expand(dot.span).expand(name.span);
}
