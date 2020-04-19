import 'dart:collection';

import 'package:dartox/src/runtime_error.dart';
import 'package:dartox/src/token.dart';

class Environment {
  /// Stores identifiers and their corresponding values.
  final HashMap<String, Object> values = HashMap();

  /// Returns value bound to the variable found by token lexeme.
  /// Otherwise, we make it a runtime time error to avoid making recursive
  /// declarations difficult.
  Object get(Token name) {
    if (values.containsKey(name.lexeme)) {
      return values[name.lexeme];
    }

    throw RuntimeError(name, "Undefined variable '" + name.lexeme + "'.");
  }

  /// Updates value of the variable.
  /// Does not create a new variable in the map.
  void assign(Token name, Object value) {
    if (values.containsKey(name.lexeme)) {
      values[name.lexeme] = value;
      return;
    } else {
      throw RuntimeError(name, "Undefined variable '" + name.lexeme + "'.");
    }
  }

  /// Adds a new variable to the map.
  void define(String name, Object value) =>
      values.putIfAbsent(name, () => value);
}
