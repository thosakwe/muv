import 'package:source_span/source_span.dart';
import 'ast_node.dart';
import 'expression.dart';
import 'identifier.dart';
import 'parameter.dart';
import 'statement.dart';
import 'token.dart';

class VariableDeclarationStatement extends Statement {
  final Token $const, let, semi;
  final List<VariableDeclaration> variableDeclarations;

  VariableDeclarationStatement(
      this.$const, this.let, this.variableDeclarations, this.semi);

  bool get isConst => $const != null;

  bool get isLet => let != null;

  Token get keyword => $const ?? let;

  @override
  List<String> get comments => keyword.comments;

  @override
  FileSpan get span {
    var s = variableDeclarations.fold<FileSpan>(
        keyword.span, (out, d) => out.expand(d.span));
    return semi == null ? s : s.expand(semi.span);
  }
}

class VariableDeclaration extends AstNode {
  final Identifier name;
  final Token equals;
  final Expression expression;

  VariableDeclaration(this.name, this.equals, this.expression);

  @override
  List<String> get comments => name.comments;

  @override
  FileSpan get span {
    if (equals == null) return name.span;
    return name.span.expand(equals.span).expand(expression.span);
  }
}

class DestructuringAssignmentStatement extends Statement {
  final Token $const, let, equals, semi;
  final DestructuringParameter destructuringParameter;
  final Expression expression;

  DestructuringAssignmentStatement(this.$const, this.let,
      this.destructuringParameter, this.equals, this.expression, this.semi);

  @override
  List<String> get comments => keyword.comments;

  bool get isConst => $const != null;

  bool get isLet => let != null;

  Token get keyword => $const ?? let;

  @override
  FileSpan get span {
    var s = keyword.span
        .expand(equals.span)
        .expand(destructuringParameter.span)
        .expand(equals.span)
        .expand(expression.span);
    return semi == null ? s : s.expand(semi.span);
  }
}
