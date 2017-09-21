import 'package:source_span/source_span.dart';
import 'ast_node.dart';
import 'expression.dart';
import 'identifier.dart';
import 'token.dart';

class ObjectLiteral extends Expression {
  final Token lCurly, rCurly;
  final List<ObjectLiteralMember> members;

  ObjectLiteral(this.lCurly, this.members, this.rCurly);

  @override
  List<String> get comments => lCurly.comments;

  @override
  FileSpan get span {
    return members
        .fold<FileSpan>(lCurly.span, (out, m) => out.expand(m.span))
        .expand(rCurly.span);
  }
}

abstract class ObjectLiteralMember extends AstNode {}

class KeyValuePair extends ObjectLiteralMember {
  final Identifier key;
  final Token colon;
  final Expression value;

  KeyValuePair(this.key, this.colon, this.value);

  @override
  List<String> get comments => key.comments;

  @override
  FileSpan get span {
    if (colon == null) return key.span;
    return key.span.expand(colon.span).expand(value.span);
  }
}

class DestructuringMember extends ObjectLiteralMember {
  final Token ellipsis;
  final Expression expression;

  DestructuringMember(this.ellipsis, this.expression);

  @override
  List<String> get comments => ellipsis.comments;

  @override
  FileSpan get span => ellipsis.span.expand(expression.span);
}