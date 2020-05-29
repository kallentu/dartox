import 'package:dartox/src/dartox_callable.dart';
import 'package:dartox/src/dartox_function.dart';
import 'package:dartox/src/dartox_getter.dart';
import 'package:dartox/src/dartox_instance.dart';
import 'package:dartox/src/interpreter.dart';
import 'package:dartox/src/token.dart';

/// Runtime representation of a class.
class DartoxClass extends DartoxInstance implements DartoxCallable {
  final String name;
  final Map<String, DartoxFunction> _methods;
  final Map<Token, DartoxFunction> _staticMethods;
  final Map<Token, DartoxGetter> _getters;

  /// A DartoxClass has no available methods that aren't static that can be used.
  /// If we end up calling it as an instance, we throw and error in [DartoxInstance].
  DartoxClass(this.name, this._methods, this._staticMethods, this._getters) : super(null) {
    // Only static methods can be called at class level.
    _staticMethods.forEach((name, fn) => super.set(name, fn));
  }

  @override
  String toString() => name;

  @override
  int arity() {
    DartoxFunction initializer = findMethod("init");
    if (initializer != null) return initializer.arity();
    return 0;
  }

  @override
  Object call(Interpreter interpreter, List<Object> arguments) {
    DartoxInstance instance = DartoxInstance(this);

    // Initialize the getter fields as we create the class.
    _getters.forEach((name, getter) => instance.set(name, getter));

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
