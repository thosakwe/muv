import 'package:build_runner/build_runner.dart';
import 'package:muv/muv.dart';
import 'package:muv_builder/muv_builder.dart';

main(List<String> args) async {
  var results = muvArgParser.parse(args);
  var inputs = results.rest.isNotEmpty ? results.rest : ['**/*.muv'];
  var buildActions = [
    // TODO: Package name...?
    new BuildAction(
      new MuvJavaScriptBuilder(
        buildOptions: new MuvOptions.fromArgResults(results),
      ),
      'muv',
      inputs: inputs,
    ),
  ];

  if (results['watch'])
    return await watch(buildActions, deleteFilesByDefault: true);
  else
    return await build(buildActions, deleteFilesByDefault: true);
}
