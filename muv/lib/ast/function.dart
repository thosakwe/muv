import 'package:source_span/source_span.dart';
import 'expression.dart';
import 'identifier.dart';
import 'parameter.dart';
import 'statement.dart';
import 'token.dart';
import 'type.dart';

abstract class FunctionNode extends Expression {
  Identifier get name;
  ParameterList get parameterList;
  TypeNode get returnType;
  List<Statement> get statements;
}

class BlockFunction extends FunctionNode {
  final Token function;
  final Identifier name;
  final ParameterList parameterList;
  final TypeNode returnType;
  final Token colon, lCurly, rCurly;
  final List<Statement> statements;

  BlockFunction(this.function, this.name, this.parameterList, this.colon, this.returnType,
      this.lCurly, this.statements, this.rCurly);

  @override
  List<String> get comments => function.comments;

  @override
  FileSpan get span {
    var s = function.span;
    if (name != null) s = s.expand(name.span);
    s = s.expand(parameterList.span);

    if (this.colon != null) {
      s = s.expand(colon.span);
      if (returnType != null) s = s.expand(returnType.span);
    }

    s = s.expand(lCurly.span);

    if (statements.isNotEmpty) {
      s = s.expand(statements.map((s) => span).reduce((a, b) => a.expand(b)));
    }

    return s.expand(rCurly.span);
  }
}
