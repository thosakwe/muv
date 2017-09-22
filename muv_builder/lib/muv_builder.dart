import 'dart:async';
import 'package:build/build.dart';
import 'package:muv/muv.dart';
import 'src/filesystem.dart';

class MuvJavaScriptBuilder implements Builder {
  final String generatedExtension;
  final MuvOptions buildOptions;

  const MuvJavaScriptBuilder(
      {this.generatedExtension: '.js',
      this.buildOptions: MuvOptions.defaultOptions});

  String _stripFirst(Uri uri) {
    return uri.pathSegments.length == 1
        ? uri.path
        : uri.pathSegments.skip(1).join('/');
  }

  @override
  Map<String, List<String>> get buildExtensions {
    var ext = [generatedExtension, '$generatedExtension.map'];
    return {
      '.muv': ext,
      '.muv.js': ext,
    };
  }

  @override
  Future build(BuildStep buildStep) async {
    var fs = new AssetFileSystem(buildStep);
    var result = await compile<String>(
      new MuvFile(
        buildStep.inputId.uri,
        await buildStep.readAsString(buildStep.inputId),
      ),
      fs,
      () => new MuvJavaScriptCompiler(),
      print,
      buildOptions: buildOptions,
    );

    var mapExtension =
        buildStep.inputId.changeExtension('$generatedExtension.map');
    var mapPath = _stripFirst(mapExtension.uri);

    buildStep.writeAsString(
      buildStep.inputId.changeExtension(generatedExtension),
      result.result + '\n//#sourceMappingURL=$mapPath',
    );

    buildStep.writeAsString(
      mapExtension,
      result.sourceMapBuilder.toJson(
        _stripFirst(buildStep.inputId.uri),
      ),
    );
  }
}
