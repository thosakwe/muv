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

    if (ctx.options.devMode) {
      var imports =
          program.topLevelDeclarations.where((t) => t is ImportDeclaration);
      var afterRequire = new CodeBuffer();
      var i = 0;

      buf.write('define(["require"');

      for (ImportDeclaration decl in imports) {
        var depName = '_require${i++}';
        buf.write(', ');
        buf.write(decl.string.span.text);

        for (var source in decl.sources) {
          var target = source.target;

          if (target is NamespacedImportTarget) {
            if (source.alias == null) {
              errors.add(new MuvError(
                  MuvErrorSeverity.WARNING,
                  'No alias provided for namespaced import. It will be ignored.',
                  decl.span));
            } else {
              var name = source.alias.name;
              afterRequire.writeln('var $name = $depName;');
            }
          }

          if (target is DefaultImportTarget) {
            var name = source.alias?.name ?? target.identifier.name;
            afterRequire.writeln('var $name = $depName.default || $depName;');
          }

          if (target is DestructuringImportTarget) {
            for (var property in target.destructuringParameter.properties) {
              // TODO: Check for property alias
              var name = property.name.name;
              afterRequire
                  .writeln('var $name = $depName.${property.name.name};');
            }
          }
        }
      }

      buf.write('], function(require');

      for (int j = 0; j < i; j++) {
        buf.write(', _require$j');
      }

      buf.writeln(') {');
      buf.indent();
      afterRequire.copyInto(buf);
    }

    program.topLevelDeclarations
        .forEach((decl) => compileTopLevel(decl, ctx, scope, buf));

    // Compute exports...
    if (ctx.options.devMode) {
      var exports = {};

      for (var decl in program.topLevelDeclarations) {
        if (decl is DefaultExportDeclaration) {
          exports['default'] =
              compileExpression(decl.expression, ctx, scope, buf);
        } else if (decl is NamedExportDeclaration) {
          if (decl.variableDeclarationStatement.isVar) {
            errors.add(new MuvError(
                MuvErrorSeverity.WARNING,
                'Exports must use "const" or "let". This export will be ignored, as it uses "var".',
                decl.variableDeclarationStatement.$var.span));
          } else {
            for (var varDecl
                in decl.variableDeclarationStatement.variableDeclarations) {
              exports[varDecl.name.name] =
                  compileExpression(varDecl.expression, ctx, scope, buf);
            }
          }
        } else if (decl is FunctionExportDeclaration) {
          if (decl.blockFunction.name == null) {
            errors.add(new MuvError(
                MuvErrorSeverity.WARNING,
                'This function has no name. It will not be exported.',
                decl.blockFunction.span));
          } else {
            exports[decl.blockFunction.name.name] =
                compileExpression(decl.blockFunction, ctx, scope, buf);
          }
        }
      }

      if (exports.isNotEmpty) {
        int i = 0;
        buf
          ..writeln('return {')
          ..indent();

        exports.forEach((key, val) {
          if (i++ > 0) buf.writeln(',');
          buf.write('$key: $val');
        });

        buf
          ..writeln()
          ..outdent()
          ..writeln('};');
      }
    }

    if (ctx.options.devMode) {
      buf.outdent();
      buf.writeln('});');
    }

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

    if (statement is DestructuringAssignmentStatement)
      compileDestructuringAssignmentStatement(statement, ctx, scope, buf);

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

  void compileDestructuringAssignmentStatement(
      DestructuringAssignmentStatement statement,
      MuvCompilationContext ctx,
      SymbolTable<MuvObject> scope,
      CodeBuffer buf) {
    String tempName = '_destruct0',
        tempValue = compileExpression(statement.expression, ctx, scope, buf);
    int i = 0;
    Variable existing = scope.resolve(tempName);

    while (existing != null) {
      tempName = '_destruct${++i}';
      existing = scope.resolve(tempName);
    }

    // TODO: Define a value here...
    scope.add(tempName);
    buf.writeln('var $tempName = $tempValue;');

    for (var property in statement.destructuringParameter.properties) {
      var name = property.name.name;
      buf.writeln('var $name = $tempName.$name;');
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

    if (expression is NewExpression)
      return compileNewExpression(expression, ctx, scope, buf);

    if (expression is BinaryExpression)
      return compileBinaryExpression(expression, ctx, scope, buf);

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
    if (array.items.isEmpty) return '[]';

    if (array.items.every((i) => i is Expression)) {
      var items = array.items.map((a) => compileExpression(a, ctx, scope, buf));
      return '[' + items.join(', ') + ']';
    }

    var items = array.items.map<String>((item) {
      Expression e;
      if (item is Expression)
        e = item;
      else if (item is DestructuringMember) e = item.expression;
      return compileExpression(e, ctx, scope, buf);
    });

    var paren = items.map<String>((e) => '($e)');
    return paren.reduce((a, b) => '$a.concat($b)');
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

  String compileNewExpression(NewExpression newExpression, MuvCompilationContext ctx,
      SymbolTable<MuvObject> scope, CodeBuffer buf) {
    var call = compileExpression(newExpression.call, ctx, scope, buf);
    return 'new $call';
  }

  String compileBinaryExpression(BinaryExpression binaryExpression, MuvCompilationContext ctx,
      SymbolTable<MuvObject> scope, CodeBuffer buf) {
    var right = compileExpression(binaryExpression.right, ctx, scope, buf);
    var left = compileExpression(binaryExpression.left, ctx, scope, buf);
    return '($left) ${binaryExpression.operator.span.text} ($right)';
  }
}
