import 'package:source_span/source_span.dart';

abstract class AstNode {
  List<String> get comments;
  FileSpan get span;
}