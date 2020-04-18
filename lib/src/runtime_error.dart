import 'package:dartox/src/token.dart';

class RuntimeError implements Exception {
  final Token token;
  final String message;

  RuntimeError(this.token, this.message);

  @override
  String toString() => message;
}
