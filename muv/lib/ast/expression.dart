import 'ast_node.dart';

abstract class Expression extends AstNode {}

abstract class Literal extends Expression {
  get value;
}
