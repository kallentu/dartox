import 'package:dartox/src/runtime_error.dart';

class ReturnException implements Exception {
  final Object value;

  ReturnException(this.value);
}
