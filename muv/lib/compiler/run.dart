import 'dart:async';
import 'package:source_maps/source_maps.dart';
import 'package:symbol_table/symbol_table.dart';
import '../analysis/analysis.dart';
import '../text/text.dart';
import 'compiler.dart';

abstract class MuvFileSystem {
  MuvFile resolve(Uri path);
}

abstract class MuvFile {
  Uri get uri;
  factory MuvFile(Uri uri, String contents) = _MemoryMuvFile;
  Future<String> readAsString();
}

class _MemoryMuvFile implements MuvFile {
  final Uri uri;
  final String contents;

  _MemoryMuvFile(this.uri, this.contents);

  @override
  Future<String> readAsString() => new Future<String>.value(contents);
}

/// Applies tree-shaking and transforms to a [sourceFile], and then compiles into the target format.
Future<MuvCompilationResult<T>> compile<T>(
    MuvFile sourceFile, MuvFileSystem fileSystem, MuvCompiler<T> compilerFactory(), void onError(MuvError error)) async {
  // TODO: Tree-shaking, other transforms...
  var scope = new SymbolTable<MuvObject>();
  var contents = await sourceFile.readAsString();
  var ctx = new MuvCompilationContext(sourceFile.uri);
  var scanner = new Scanner(contents, sourceFile.uri)..scan();
  scanner.errors.forEach(onError);
  var parser = new Parser(scanner);
  var program = parser.parseProgram();
  parser.errors.forEach(onError);
  var c = compilerFactory();
  var result = c.compile(program, ctx, scope);
  c.errors.forEach(onError);
  return new MuvCompilationResult<T>(result, ctx.sourceMapBuilder);
}

class MuvCompilationResult<T> {
  final T result;
  final SourceMapBuilder sourceMapBuilder;

  MuvCompilationResult(this.result, this.sourceMapBuilder);
}