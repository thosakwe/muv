import 'package:args/args.dart';

final ArgParser muvArgParser = new ArgParser(allowTrailingOptions: true)
  ..addFlag('dev',
      help: 'Build in development mode (ideal for incremental builds)',
      negatable: false);

class MuvOptions {
  // Determines how imports are resolved, among other things.
  final bool devMode;

  const MuvOptions({this.devMode});

  static const MuvOptions defaultOptions = const MuvOptions(
    devMode: false,
  );

  factory MuvOptions.fromArgResults(ArgResults results) {
    return new MuvOptions(
      devMode: results['dev'],
    );
  }
}
