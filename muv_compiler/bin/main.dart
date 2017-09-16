import 'package:args/args.dart';
import 'package:build_runner/build_runner.dart';
import 'package:muv_builder/muv_builder.dart';

final ArgParser argParser = new ArgParser()
  ..addFlag('watch',
      abbr: 'w',
      help: 'Watch for, and re-build on, filesystem changes.',
      negatable: false);

main(List<String> args) async {
  var result = argParser.parse(args);
  var inputs = result.rest.isNotEmpty ? result.rest : ['**/*.muv'];
  var buildActions = [
    // TODO: Package name...?
    new BuildAction(new MuvJavaScriptBuilder(), 'muv', inputs: inputs),
  ];

  if (result['watch'])
    return await watch(buildActions, deleteFilesByDefault: true);
  else
    return await build(buildActions, deleteFilesByDefault: true);
}
