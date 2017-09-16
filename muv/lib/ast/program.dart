import 'package:source_span/source_span.dart';
import 'ast_node.dart';
import 'top_level.dart';

class Program extends AstNode {
  final List<TopLevel> topLevelDeclarations;

  Program(this.topLevelDeclarations);

  @override
  List<String> get comments => [];

  @override
  FileSpan get span {
    return topLevelDeclarations
        .map((t) => t.span)
        .reduce((a, b) => a.expand(b));
  }
}
