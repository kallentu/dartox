import 'package:dartox/src/interpreter.dart';

/// Dart representation of any Dartox object that can be called like a function.
abstract class DartoxCallable {
  /// Number of arguments it expects.
  int arity();
  Object call(Interpreter interpreter, List<Object> arguments);
}
