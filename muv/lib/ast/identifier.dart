import 'package:source_span/source_span.dart';
import 'expression.dart';
import 'token.dart';

class Identifier extends Expression {
  final Token id;

  Identifier(this.id);

  @override
  List<String> get comments => id.comments;

  String get name => id.span.text;

  @override
  FileSpan get span => id.span;
}