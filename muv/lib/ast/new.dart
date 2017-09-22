import 'package:source_span/source_span.dart';
import 'call.dart';
import 'expression.dart';
import 'token.dart';

class NewExpression extends Expression {
  final Token $new;
  final Call call;

  NewExpression(this.$new, this.call);

  @override
  List<String> get comments => $new.comments;

  @override
  FileSpan get span => $new.span.expand(call.span);
}