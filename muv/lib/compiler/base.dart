import 'package:source_maps/source_maps.dart';
import 'package:symbol_table/symbol_table.dart';
import '../analysis/analysis.dart';
import '../ast/ast.dart';
import '../text/text.dart';
import '../options.dart';

abstract class MuvCompiler<T> {
  final List<MuvError> errors = [];

  T compile(
      Program program, MuvCompilationContext ctx, SymbolTable<MuvObject> scope);
}

class MuvCompilationContext {
  final SourceMapBuilder sourceMapBuilder = new SourceMapBuilder();
  final Uri entryPoint;
  final MuvOptions options;

  MuvCompilationContext(this.entryPoint,
      {this.options: MuvOptions.defaultOptions});
}
