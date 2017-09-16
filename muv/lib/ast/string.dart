import 'package:charcode/charcode.dart';
import 'package:source_span/source_span.dart';
import '../text/text.dart';
import 'expression.dart';
import 'token.dart';

class StringLiteral extends Literal {
  final Token string;
  final String value;

  StringLiteral(this.string, this.value);

  static String parseValue(Token string) {
    var text = string.span.text.substring(1, string.span.text.length - 1);
    var codeUnits = text.codeUnits;
    var buf = new StringBuffer();

    for (int i = 0; i < codeUnits.length; i++) {
      var ch = codeUnits[i];

      if (ch == $backslash) {
        if (i < codeUnits.length - 5 && codeUnits[i + 1] == $u) {
          var c1 = codeUnits[i += 2],
              c2 = codeUnits[++i],
              c3 = codeUnits[++i],
              c4 = codeUnits[++i];
          var hexString = new String.fromCharCodes([c1, c2, c3, c4]);
          var hexNumber = int.parse(hexString, radix: 16);
          buf.write(new String.fromCharCode(hexNumber));
          continue;
        }

        if (i < codeUnits.length - 1) {
          var next = codeUnits[++i];

          switch (next) {
            case $b:
              buf.write('\b');
              break;
            case $f:
              buf.write('\f');
              break;
            case $n:
              buf.writeCharCode($lf);
              break;
            case $r:
              buf.writeCharCode($cr);
              break;
            case $t:
              buf.writeCharCode($tab);
              break;
            default:
              buf.writeCharCode(next);
          }
        } else
          throw new MuvError(MuvErrorSeverity.ERROR,
              'Unexpected "\\" in string literal.', string.span);
      } else {
        buf.writeCharCode(ch);
      }
    }

    return buf.toString();
  }

  @override
  List<String> get comments => string.comments;

  @override
  FileSpan get span => string.span;
}
