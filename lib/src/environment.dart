import 'dart:collection';

import 'package:dartox/src/runtime_error.dart';
import 'package:dartox/src/token.dart';

class Environment {
  /// Reference to its enclosing environment, [null] if there is none.
  final Environment enclosing;

  /// Stores identifiers and their corresponding values.
  final HashMap<String, Object> values = HashMap();

  /// Global scope environment.
  Environment() : enclosing = null;

  /// Creates local scope nested inside outer enclosing scope.
  Environment.withEnclosing(this.enclosing);

  /// Returns value bound to the variable found by token lexeme.
  /// Otherwise, we make it a runtime time error to avoid making recursive
  /// declarations difficult.
  Object get(Token name) {
    if (values.containsKey(name.lexeme)) {
      return values[name.lexeme];
    }

    // If not found in this scope, try an enclosing one.
    if (enclosing != null) return enclosing.get(name);

    throw RuntimeError(name, "Undefined variable '" + name.lexeme + "'.");
  }

  /// Updates value of the variable.
  /// Does not create a new variable in the map.
  void assign(Token name, Object value) {
    if (values.containsKey(name.lexeme)) {
      values[name.lexeme] = value;
    } else if (enclosing != null) {
      // If we cannot find variable in this environment, try the enclosing one.
      enclosing.assign(name, value);
    } else {
      throw RuntimeError(name, "Undefined variable '" + name.lexeme + "'.");
    }
  }

  /// Adds a new variable to the map.
  void define(String name, Object value) =>
      values.putIfAbsent(name, () => value);
}
