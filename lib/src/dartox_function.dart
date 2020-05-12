import 'package:dartox/src/dartox_callable.dart';
import 'package:dartox/src/dartox_instance.dart';
import 'package:dartox/src/environment.dart';
import 'package:dartox/src/interpreter.dart';
import 'package:dartox/src/exception.dart';
import 'package:dartox/src/statement.dart';

class DartoxFunction implements DartoxCallable {
  final Function _declaration;

  /// Environment that is active when function is declared, not when it's
  /// called.
  final Environment _closure;
  final bool _isInitializer;

  DartoxFunction(this._declaration, this._closure, this._isInitializer);

  @override
  int arity() => _declaration.params.length;

  @override
  Object call(Interpreter interpreter, List<Object> arguments) {
    // Bind arguments and their values in the environment of the method.
    // Create a new environment for each call, starting from the
    // environment from when it was declared.
    Environment environment = Environment.withEnclosing(_closure);
    for (int i = 0; i < _declaration.params.length; i++) {
      environment.define(
          _declaration.params.elementAt(i).lexeme, arguments.elementAt(i));
    }

    // Execute the body of the method with the new environment that encapsulates
    // the parameters and their values.
    try {
      interpreter.executeBlock(_declaration.body, environment);
    } catch (e) {
      if (e is ReturnException) {
        // Disallow returns in initializer.
        if (_isInitializer) return _closure.getAt(0, "this");

        // Make this return value of our call.
        return e.value;
      }
    }

    // init() methods always return this.
    // Avoids weird edge case when trying to invoke init() directly.
    if (_isInitializer) return _closure.getAt(0, "this");

    return null;
  }

  @override
  String toString() => "<fn " + _declaration.name.lexeme + ">";

  /// Create new environment nestled inside the method's original closure.
  /// When method is called, it will become the parent of the method body's
  /// environment. "this" is bound to the instance.
  DartoxFunction bind(DartoxInstance instance) {
    Environment environment = Environment.withEnclosing(_closure);
    environment.define("this", instance);
    return DartoxFunction(_declaration, environment, _isInitializer);
  }
}
