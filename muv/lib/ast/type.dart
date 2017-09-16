import 'package:source_span/source_span.dart';
import 'ast_node.dart';
import 'identifier.dart';

abstract class TypeNode extends AstNode {}

class SimpleType extends TypeNode {
  final Identifier name;

  SimpleType(this.name);

  @override
  List<String> get comments => name.comments;

  @override
  FileSpan get span => name.span;
}
