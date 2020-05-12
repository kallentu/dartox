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
}
