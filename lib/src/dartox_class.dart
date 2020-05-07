import 'package:dartox/src/dartox_callable.dart';
import 'package:dartox/src/dartox_instance.dart';
import 'package:dartox/src/interpreter.dart';

/// Runtime representation of a class.
class DartoxClass implements DartoxCallable {
  final String name;

  DartoxClass(this.name);

  @override
  String toString() => name;

  @override
  int arity() => 0;

  @override
  Object call(Interpreter interpreter, List<Object> arguments) =>
      DartoxInstance(this);
}
