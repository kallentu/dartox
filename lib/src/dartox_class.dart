import 'package:dartox/src/dartox_callable.dart';
import 'package:dartox/src/dartox_function.dart';
import 'package:dartox/src/dartox_instance.dart';
import 'package:dartox/src/interpreter.dart';
import 'package:dartox/src/runtime_error.dart';
import 'package:dartox/src/token.dart';

/// Runtime representation of a class.
class DartoxClass implements DartoxCallable, DartoxInstance {
  final String name;
  final Map<String, DartoxFunction> _methods;
  final Map<String, DartoxFunction> _staticMethods;

  DartoxClass(this.name, this._methods, this._staticMethods);

  @override
  String toString() => name;

  @override
  int arity() {
    DartoxFunction initializer = findMethod("init");
    if (initializer != null) initializer.arity();
    return 0;
  }

  @override
  Object call(Interpreter interpreter, List<Object> arguments) {
    DartoxInstance instance = DartoxInstance(this);

    // Dartox initializer uses "init".
    // We look for the initializer and bind, invoke it like a method call.
    DartoxFunction initializer = findMethod("init");
    if (initializer != null) {
      initializer.bind(instance).call(interpreter, arguments);
    }

    return instance;
  }

  DartoxFunction findMethod(String name) {
    if (_methods.containsKey(name)) {
      return _methods[name];
    }

    return null;
  }

  /// For getting static methods within a class, nothing else.
  @override
  Object get(Token name) {
    if (_staticMethods.containsKey(name.lexeme)) {
      return _staticMethods[name.lexeme];
    }

    // If class instance doesn't have static method, we throw an error.
    throw RuntimeError(name, "Undefined static method '${name.lexeme}'.");
  }

  /// For setting static methods within a class, nothing else.
  @override
  void set(Token name, Object value) =>
      _staticMethods.putIfAbsent(name.lexeme, () => value);
}
