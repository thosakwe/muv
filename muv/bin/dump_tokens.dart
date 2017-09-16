import 'dart:io';
import 'package:console/console.dart';
import 'package:muv/text/text.dart';

main() {
  var pen = new TextPen();

  while (true) {
    stdout.write('Enter text: ');
    var line = stdin.readLineSync();
    var scanner = new Scanner(line, Platform.script)..scan();

    if (scanner.errors.isNotEmpty) {
      for (var error in scanner.errors) {
        if (error.severity == MuvErrorSeverity.WARNING)
          pen.yellow();
        else pen.red();

        pen.call(error.toString() + '\n');
      }

      stderr.writeln(pen.buffer);
      pen.reset();
    } else {
      print('${scanner.tokens.length} token(s):');

      for (var token in scanner.tokens) {
        print('  * "${token.span.text}" => ${token.type}');
      }
    }
  }
}