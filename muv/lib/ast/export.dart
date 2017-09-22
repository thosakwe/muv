import 'package:source_span/source_span.dart';
import 'expression.dart';
import 'function.dart';
import 'top_level.dart';
import 'token.dart';
import 'variable.dart';

class DefaultExportDeclaration extends TopLevel {
  final Token $export, $default;
  final Expression expression;

  DefaultExportDeclaration(this.$export, this.$default, this.expression);

  @override
  List<String> get comments => $export.comments;

  @override
  FileSpan get span => $export.span.expand($default.span).expand(expression.span);
}

class NamedExportDeclaration extends TopLevel {
  final Token $export;
  final VariableDeclarationStatement variableDeclarationStatement;

  NamedExportDeclaration(this.$export, this.variableDeclarationStatement);

  @override
  List<String> get comments => $export.comments;

  @override
  FileSpan get span => $export.span.expand(variableDeclarationStatement.span);
}

class FunctionExportDeclaration extends TopLevel {
  final Token $export;
  final BlockFunction blockFunction;

  FunctionExportDeclaration(this.$export, this.blockFunction);

  @override
  List<String> get comments => $export.comments;

  @override
  FileSpan get span => $export.span.expand(blockFunction.span);
}