import 'package:indenting_buffer/indenting_buffer.dart';
import 'package:symbol_table/symbol_table.dart';
import '../ast/ast.dart';
import '../analysis/analysis.dart';
import '../text/text.dart';
import 'base.dart';

class MuvJavaScriptCompiler extends MuvCompiler<String> {
  String jsError(String msg) => "((function() { throw new Error('$msg'); })())";

  @override
  String compile(Program program, MuvCompilationContext ctx,
      SymbolTable<MuvObject> scope) {
    var buf = new IndentingBuffer();
    buf
      ..writeln('// Generated via Muv')
      ..writeln('((function() {')
      ..indent();
    program.topLevelDeclarations
        .forEach((decl) => compileTopLevel(decl, ctx, scope, buf));
    buf
      ..outdent()
      ..writeln('})());');
    return buf.toString();
  }

  void compileTopLevel(TopLevel declaration, MuvCompilationContext ctx,
      SymbolTable<MuvObject> scope, IndentingBuffer buf) {
    // TODO: Other top-level
    if (declaration is TopLevelStatement)
      compileTopLevelStatement(declaration, ctx, scope, buf);
  }

  void compileTopLevelStatement(
      TopLevelStatement statement,
      MuvCompilationContext ctx,
      SymbolTable<MuvObject> scope,
      IndentingBuffer buf) {
    compileStatement(statement.statement, ctx, scope, buf);
  }

  void compileStatement(Statement statement, MuvCompilationContext ctx,
      SymbolTable<MuvObject> scope, IndentingBuffer buf) {
    // TODO: Compile other statements
    if (statement is VariableDeclarationStatement)
      compileVariableDeclarationStatement(statement, ctx, scope, buf);

    if (statement is ExpressionStatement)
      compileExpressionStatement(statement, ctx, scope, buf);
  }

  void compileVariableDeclarationStatement(
      VariableDeclarationStatement statement,
      MuvCompilationContext ctx,
      SymbolTable<MuvObject> scope,
      IndentingBuffer buf) {
    // TODO: Declare variables within scope
    // TODO: handle "exists within scope"
    for (var decl in statement.variableDeclarations) {
      var expr = compileExpression(decl.expression, ctx, scope, buf);
      buf.writeln('var ${decl.name.name} = $expr;');
    }
  }

  void compileExpressionStatement(
      ExpressionStatement statement,
      MuvCompilationContext ctx,
      SymbolTable<MuvObject> scope,
      IndentingBuffer buf) {
    var expression = compileExpression(statement.expression, ctx, scope, buf);
    if (statement.expression is! BlockFunction) buf.writeln('$expression;');
  }

  String compileExpression(Expression expression, MuvCompilationContext ctx,
      SymbolTable<MuvObject> scope, IndentingBuffer buf) {
    // Literals should be virtually the same in JavaScript
    if (expression is Literal) return expression.span.text;

    if (expression is Identifier) return expression.name;

    if (expression is Call) return compileCall(expression, ctx, scope, buf);

    if (expression is MemberExpression)
      return compileMemberExpression(expression, ctx, scope, buf);

    if (expression is Array) return compileArray(expression, ctx, scope, buf);

    if (expression is BlockFunction)
      return compileBlockFunction(expression, ctx, scope, buf);

    // Fallback to error
    var msg =
        'Cannot yet compile ${expression.runtimeType} "${expression.span.text}"';
    errors.add(new MuvError(MuvErrorSeverity.ERROR, msg, expression.span));
    return jsError(msg);
  }

  String compileCall(Call call, MuvCompilationContext ctx,
      SymbolTable<MuvObject> scope, IndentingBuffer buf) {
    var target = compileExpression(call.target, ctx, scope, buf);
    var arguments =
        call.arguments.map((a) => compileExpression(a, ctx, scope, buf));
    return '$target(' + arguments.join(', ') + ')';
  }

  String compileMemberExpression(
      MemberExpression memberExpression,
      MuvCompilationContext ctx,
      SymbolTable<MuvObject> scope,
      IndentingBuffer buf) {
    // TODO: Check if name exists
    var left = compileExpression(memberExpression.expression, ctx, scope, buf);
    return '$left.${memberExpression.name.name}';
  }

  String compileArray(Array array, MuvCompilationContext ctx,
      SymbolTable<MuvObject> scope, IndentingBuffer buf) {
    var items = array.items.map((a) => compileExpression(a, ctx, scope, buf));
    return '[' + items.join(', ') + ']';
  }

  String compileBlockFunction(
      BlockFunction blockFunction,
      MuvCompilationContext ctx,
      SymbolTable<MuvObject> scope,
      IndentingBuffer buf) {
    // TODO: Define within scope as a function object
    void writeFunction(IndentingBuffer b) {
      b.write('function');

      if (blockFunction.name != null)
        b.withoutIndent(' ${blockFunction.name.name}');

      b.withoutIndent('(');

      for (int i = 0; i < blockFunction.parameterList.parameters.length; i++) {
        if (i > 0) b.withoutIndent(', ');
        var parameter = blockFunction.parameterList.parameters[i];
        b.withoutIndent(parameter.name.name);
      }

      b
        ..withoutIndent(') {\n')
        ..indent();

      blockFunction.statements
          .forEach((s) => compileStatement(s, ctx, scope, b));

      b
        ..outdent()
        ..writeln('}');
    }

    if (blockFunction.name == null) {
      // Return an anonymous function
      var anonymous = new IndentingBuffer()..write('(');
      writeFunction(anonymous);
      anonymous.withoutIndent(')');
      return anonymous.toString();
    } else {
      // Write a block function, and return its name.
      writeFunction(buf);
      return blockFunction.name.name;
    }
  }
}
