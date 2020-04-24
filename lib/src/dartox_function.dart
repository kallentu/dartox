import 'package:dartox/src/dartox_callable.dart';
import 'package:dartox/src/environment.dart';
import 'package:dartox/src/interpreter.dart';
import 'package:dartox/src/return.dart';
import 'package:dartox/src/statement.dart';

class DartoxFunction implements DartoxCallable {
  final Function _declaration;

  /// Environment that is active when function is declared, not when it's
  /// called.
  final Environment _closure;
  DartoxFunction(this._declaration, this._closure);

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
        // Make this return value of our call.
        return e.value;
      }
    }

    return null;
  }

  @override
  String toString() => "<fn " + _declaration.name.lexeme + ">";
}
