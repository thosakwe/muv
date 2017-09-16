import 'package:source_span/source_span.dart';
import 'expression.dart';
import 'token.dart';

class Call extends Expression {
  final Expression target;
  final Token lParen, rParen;
  final List<Expression> arguments;

  Call(this.target, this.lParen, this.rParen, this.arguments);

  @override
  List<String> get comments => target.comments;

  @override
  FileSpan get span {
    return arguments
        .fold<FileSpan>(lParen.span, (out, a) => out.expand(a.span))
        .expand(rParen.span);
  }
}
