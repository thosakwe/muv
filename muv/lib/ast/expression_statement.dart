import 'package:source_span/source_span.dart';
import 'expression.dart';
import 'statement.dart';
import 'token.dart';

class ExpressionStatement extends Statement {
  final Expression expression;
  final Token semi;

  ExpressionStatement(this.expression, this.semi);

  @override
  List<String> get comments => expression.comments;

  @override
  FileSpan get span {
    if (semi == null) return expression.span;
    return expression.span.expand(semi.span);
  }
}
