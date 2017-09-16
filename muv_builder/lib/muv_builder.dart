import 'dart:async';
import 'package:build/build.dart';
import 'package:muv/muv.dart';
import 'src/filesystem.dart';

class MuvJavaScriptBuilder implements Builder {
  final String generatedExtension;

  const MuvJavaScriptBuilder({this.generatedExtension: '.js'});

  @override
  Map<String, List<String>> get buildExtensions {
    return {
      '.muv': [generatedExtension]
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
    );
    buildStep.writeAsString(
        buildStep.inputId.changeExtension(generatedExtension), result);
  }
}
