import 'package:source_span/source_span.dart';

String severityToString(MuvErrorSeverity severity) {
  switch (severity) {
    case MuvErrorSeverity.WARNING:
      return 'warning';
    case MuvErrorSeverity.ERROR:
      return 'error';
    default:
      throw new ArgumentError('Invalid error severity.');
  }
}

class MuvError extends Error {
  final MuvErrorSeverity severity;
  final String message;
  final FileSpan span;

  MuvError(this.severity, this.message, this.span);

  @override
  String toString() {
    var location =
        '${span.sourceUrl}, line ${span.start.line} pos ${span.start.column}';
    return severityToString(severity) +
        ': $location: $message \n' +
        span.highlight(color: true);
  }
}

enum MuvErrorSeverity { WARNING, ERROR }
