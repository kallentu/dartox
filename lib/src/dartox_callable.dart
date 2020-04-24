import 'package:dartox/src/interpreter.dart';

/// Dart representation of any Dartox object that can be called like a function.
abstract class DartoxCallable {
  /// Number of arguments it expects.
  int arity();
  Object call(Interpreter interpreter, List<Object> arguments);
}

/// Clock that tells current time in seconds.
class ClockCallable implements DartoxCallable {
  @override
  int arity() => 0;

  @override
  Object call(Interpreter interpreter, List<Object> arguments) =>
      DateTime.now().millisecondsSinceEpoch / 1000.0;

  @override
  String toString() => "<native fn>";
}
