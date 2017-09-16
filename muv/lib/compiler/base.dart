import 'package:symbol_table/symbol_table.dart';
import '../analysis/analysis.dart';
import '../ast/ast.dart';
import '../text/text.dart';

abstract class MuvCompiler<T> {
  final List<MuvError> errors = [];

  T compile(
      Program program, MuvCompilationContext ctx, SymbolTable<MuvObject> scope);
}

class MuvCompilationContext {

}
