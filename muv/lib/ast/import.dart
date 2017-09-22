import 'package:source_span/source_span.dart';
import 'ast_node.dart';
import 'identifier.dart';
import 'parameter.dart';
import 'string.dart';
import 'token.dart';
import 'top_level.dart';

class ImportDeclaration extends TopLevel {
  final Token $import, from, semi;
  final List<ImportSource> sources;
  final StringLiteral string;

  ImportDeclaration(this.$import, this.sources, this.from, this.string, this.semi);

  @override
  List<String> get comments {
    return $import.comments;
  }

  @override
  FileSpan get span {
    var s = sources.fold<FileSpan>($import.span, (out, s) => out.expand(s.span));
    if (sources.isNotEmpty) s = s.expand(from.span);
    s = s.expand(string.span);
    return semi == null ? s : s.expand(semi.span);
  }
}

class ImportSource extends AstNode {
  final ImportTarget target;
  final Token $as;
  final Identifier alias;

  ImportSource(this.target, this.$as,  this.alias);

  @override
  List<String> get comments => target.comments;

  @override
  FileSpan get span {
    var s = target.span;

    if ($as != null) {
      s = s.expand($as.span).expand(alias.span);
    }

    return s;
  }
}

abstract class ImportTarget extends AstNode {
}

class DefaultImportTarget extends ImportTarget {
  final Identifier identifier;

  DefaultImportTarget(this.identifier);

  @override
  List<String> get comments => identifier.comments;

  @override
  FileSpan get span => identifier.span;
}

class DestructuringImportTarget extends ImportTarget {
  final DestructuringParameter destructuringParameter;

  DestructuringImportTarget(this.destructuringParameter);

  @override
  List<String> get comments => destructuringParameter.comments;

  @override
  FileSpan get span => destructuringParameter.span;
}

class NamespacedImportTarget extends ImportTarget {
  final Token asterisk;

  NamespacedImportTarget(this.asterisk);

  @override
  List<String> get comments => asterisk.comments;

  @override
  FileSpan get span => asterisk.span;
}