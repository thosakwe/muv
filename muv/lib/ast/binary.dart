import 'package:source_span/source_span.dart';
import 'expression.dart';
import 'token.dart';

class BinaryExpression extends Expression {
  final Expression left, right;
  final Token operator;

  BinaryExpression(this.left, this.operator, this.right);

  @override
  List<String> get comments => left.comments;

  @override
  FileSpan get span => left.span.expand(operator.span).expand(right.span);
}
