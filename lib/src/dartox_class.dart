import 'package:dartox/src/dartox_callable.dart';
import 'package:dartox/src/dartox_function.dart';
import 'package:dartox/src/dartox_instance.dart';
import 'package:dartox/src/interpreter.dart';

/// Runtime representation of a class.
class DartoxClass implements DartoxCallable {
  final String name;
  final Map<String, DartoxFunction> _methods;

  DartoxClass(this.name, this._methods);

  @override
  String toString() => name;

  @override
  int arity() => 0;

  @override
  Object call(Interpreter interpreter, List<Object> arguments) =>
      DartoxInstance(this);

  DartoxFunction findMethod(String name) {
    if (_methods.containsKey(name)) {
      return _methods[name];
    }

    return null;
  }
}
