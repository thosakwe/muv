import 'package:build_runner/build_runner.dart';
import 'package:muv/muv.dart';
import 'package:muv_builder/muv_builder.dart';

final List<BuildAction> buildActions = [
  new BuildAction(
    new MuvJavaScriptBuilder(
      buildOptions: const MuvOptions(
        devMode: true,
      ),
    ),
    'example',
    inputs: const ['*.muv'],
  ),
];
