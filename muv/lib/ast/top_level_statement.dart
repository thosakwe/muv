import 'package:source_span/source_span.dart';
import 'statement.dart';
import 'top_level.dart';

class TopLevelStatement extends TopLevel {
  final Statement statement;

  TopLevelStatement(this.statement);

  @override
  List<String> get comments => statement.comments;

  @override
  FileSpan get span => statement.span;
}