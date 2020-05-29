import 'dart:collection';

import 'package:dartox/src/dartox_class.dart';
import 'package:dartox/src/dartox_function.dart';
import 'package:dartox/src/dartox_getter.dart';
import 'package:dartox/src/runtime_error.dart';
import 'package:dartox/src/token.dart';

/// Runtime representation of an instance of a Dartox class.
class DartoxInstance {
  DartoxClass _clas;
  final Map<String, Object> _fields = HashMap();

  DartoxInstance(this._clas);

  @override
  String toString() => _clas.name + " instance";

  Object get(Token name) {
    if (_fields.containsKey(name.lexeme)) {
      Object field = _fields[name.lexeme];

      // If getter, must bind 'this' to the environment.
      return field is DartoxGetter ? field.bind(this) : field;
    }

    // See [DartoxClass] initialization.
    if (_clas == null) {
      throw RuntimeError(name,
          "No class defined for DartoxInstance while finding '${name.lexeme}'.");
    }

    DartoxFunction method = _clas.findMethod(name.lexeme);
    if (method != null) return method.bind(this);

    // If instance doesn't have field, we throw an error.
    throw RuntimeError(name, "Undefined property '${name.lexeme}'.");
  }

  void set(Token name, Object value) =>
      _fields.putIfAbsent(name.lexeme, () => value);
}
