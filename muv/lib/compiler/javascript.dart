import 'package:code_buffer/code_buffer.dart';
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
    var buf = new CodeBuffer(sourceUrl: ctx.entryPoint);
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
      SymbolTable<MuvObject> scope, CodeBuffer buf) {
    // TODO: Other top-level
    if (declaration is TopLevelStatement)
      compileTopLevelStatement(declaration, ctx, scope, buf);
  }

  void compileTopLevelStatement(TopLevelStatement statement,
      MuvCompilationContext ctx, SymbolTable<MuvObject> scope, CodeBuffer buf) {
    compileStatement(statement.statement, ctx, scope, buf);
  }

  void compileStatement(Statement statement, MuvCompilationContext ctx,
      SymbolTable<MuvObject> scope, CodeBuffer buf) {
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
      CodeBuffer buf) {
    // TODO: Declare variables within scope
    // TODO: handle "exists within scope"
    for (var decl in statement.variableDeclarations) {
      var expr = compileExpression(decl.expression, ctx, scope, buf);
      buf.writeln('var ${decl.name.name} = $expr;');
      //ctx.sourceMapBuilder.addSpan(decl.span, buf.lastLine.span);
    }
  }

  void compileExpressionStatement(ExpressionStatement statement,
      MuvCompilationContext ctx, SymbolTable<MuvObject> scope, CodeBuffer buf) {
    var expression = compileExpression(statement.expression, ctx, scope, buf);
    if (statement.expression is! BlockFunction) {
      buf.writeln('$expression;');
      //ctx.sourceMapBuilder.addSpan(statement.span, buf.lastLine.span);
    }
  }

  String compileExpression(Expression expression, MuvCompilationContext ctx,
      SymbolTable<MuvObject> scope, CodeBuffer buf) {
    // Literals should be virtually the same in JavaScript
    if (expression is Literal) return expression.span.text;

    if (expression is Identifier) return expression.name;

    if (expression is Call) return compileCall(expression, ctx, scope, buf);

    if (expression is MemberExpression)
      return compileMemberExpression(expression, ctx, scope, buf);

    if (expression is ObjectLiteral)
      return compileObjectLiteral(expression, ctx, scope, buf);

    if (expression is Array) return compileArray(expression, ctx, scope, buf);

    if (expression is BlockFunction) {
      var result = compileBlockFunction(expression, ctx, scope, buf);

      if (result is! CodeBuffer) {
        buf.writeln();
        return result;
      }

      (result as CodeBuffer).copyInto(buf);
      //ctx.sourceMapBuilder.addSpan(expression.span, buf.lastLine.span);
      return '';
    }

    // Fallback to error
    var msg =
        'Cannot yet compile ${expression.runtimeType} "${expression.span.text}"';
    errors.add(new MuvError(MuvErrorSeverity.ERROR, msg, expression.span));
    return jsError(msg);
  }

  String compileCall(Call call, MuvCompilationContext ctx,
      SymbolTable<MuvObject> scope, CodeBuffer buf) {
    var target = compileExpression(call.target, ctx, scope, buf);
    var arguments =
        call.arguments.map((a) => compileExpression(a, ctx, scope, buf));
    return '$target(' + arguments.join(', ') + ')';
  }

  String compileMemberExpression(MemberExpression memberExpression,
      MuvCompilationContext ctx, SymbolTable<MuvObject> scope, CodeBuffer buf) {
    // TODO: Check if name exists
    var left = compileExpression(memberExpression.expression, ctx, scope, buf);
    return '$left.${memberExpression.name.name}';
  }

  String compileObjectLiteral(ObjectLiteral objectLiteral,
      MuvCompilationContext ctx, SymbolTable<MuvObject> scope, CodeBuffer buf) {
    if (!objectLiteral.members.any((m) => m is DestructuringMember)) {
      var b = new StringBuffer('{');
      int i = 0;

      for (KeyValuePair member in objectLiteral.members) {
        if (i++ > 0) b.write(', ');

        if (member.value == null) {
          b.write('${member.key.name}: ${member.key.name}');
        } else {
          var value = compileExpression(member.value, ctx, scope, buf);
          b.write('${member.key.name}: $value');
        }
      }

      b.write('}');
      return b.toString();
    }

    var keys = <String>['{}'];

    for (var member in objectLiteral.members) {
      if (member is DestructuringMember) {
        keys.add(compileExpression(member.expression, ctx, scope, buf));
      } else if (member is KeyValuePair) {
        if (member.value == null) {
          keys.add('{${member.key.name}: ${member.key.name}}');
        } else {
          var value = compileExpression(member.value, ctx, scope, buf);
          keys.add('{${member.key.name}: $value}');
        }
      }
    }

    return 'Object.assign(' + keys.join(', ') + ')';
  }

  String compileArray(Array array, MuvCompilationContext ctx,
      SymbolTable<MuvObject> scope, CodeBuffer buf) {
    var items = array.items.map((a) => compileExpression(a, ctx, scope, buf));
    return '[' + items.join(', ') + ']';
  }

  compileBlockFunction(BlockFunction blockFunction, MuvCompilationContext ctx,
      SymbolTable<MuvObject> scope, CodeBuffer buf) {
    // TODO: Define within scope as a function object
    var b = new CodeBuffer();
    b.write('function');

    if (blockFunction.name != null) b.write(' ${blockFunction.name.name}');

    b.write('(');

    int i = 0;

    for (var parameter in blockFunction.parameterList.parameters) {
      if (i > 0) b.write(', ');
      if (parameter is SimpleParameter)
        b.write(parameter.name.name);
      else
        b.write('arg$i');
      i++;
    }

    b
      ..writeln(') {')
      ..indent();

    i = 0;
    for (var parameter in blockFunction.parameterList.parameters) {
      if (parameter is DestructuringParameter) {
        var argLiteral = 'arg$i';

        for (var property in parameter.properties) {
          b.writeln(
              'var ${property.name.name} = $argLiteral.${property.name.name};');
        }
      }

      i++;
    }

    blockFunction.statements.forEach((s) => compileStatement(s, ctx, scope, b));

    b
      ..outdent()
      ..writeln('}');

    if (blockFunction.name == null) {
      // Return an anonymous function
      var anonymous = new CodeBuffer()..write('(');
      b.copyInto(anonymous);
      anonymous.write(')');
      return anonymous;
    } else {
      // Write a block function, and return its name.
      b.copyInto(buf);
      return blockFunction.name.name;
    }
  }
}
