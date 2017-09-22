import 'object.dart';

abstract class Expression extends ArrayLiteralMember {}

abstract class Literal extends Expression {
  get value;
}
