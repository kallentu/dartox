import 'package:dartox/src/dartox_instance.dart';
import 'package:dartox/src/environment.dart';
import 'package:dartox/src/exception.dart';
import 'package:dartox/src/interpreter.dart';
import 'package:dartox/src/statement.dart';

/// Getter methods that are defined as block methods without parameters.
///
/// Example input for getters:
/// class Circle{ init(r) { this.r = r; } area { return 3.14 * this.r * this.r; } }
/// print Circle(3).area;
class DartoxGetter {
  final Getter _declaration;

  /// Environment that is active when function is declared, not when it's
  /// called.
  final Environment _closure;

  DartoxGetter(this._declaration, this._closure);

  @override
  String toString() => "<getter " + _declaration.name.lexeme + ">";

  /// Execute the statements within the getter.
  Object execute(Interpreter interpreter) {
    Environment environment = Environment.withEnclosing(_closure);
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

  /// Create new environment nestled inside the method's original closure.
  /// When getter is called, it will become the parent of the getter body's
  /// environment. "this" is bound to the instance.
  DartoxGetter bind(DartoxInstance instance) {
    Environment environment = Environment.withEnclosing(_closure);
    environment.define("this", instance);
    return DartoxGetter(_declaration, environment);
  }
}