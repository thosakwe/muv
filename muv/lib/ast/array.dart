import 'package:source_span/source_span.dart';
import 'expression.dart';
import 'object.dart';
import 'token.dart';

class Array extends Expression {
  final Token lBracket, rBracket;
  final List<ArrayLiteralMember> items;

  Array(this.lBracket, this.rBracket, this.items);

  @override
  List<String> get comments => lBracket.comments;

  @override
  FileSpan get span {
    return items
        .fold<FileSpan>(lBracket.span, (out, i) => out.expand(i.span))
        .expand(rBracket.span);
  }
}