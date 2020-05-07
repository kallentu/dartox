import 'dart:collection';

import 'package:dartox/src/dartox_class.dart';
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
      return _fields[name.lexeme];
    }

    // If instance doesn't have field, we throw an error.
    throw RuntimeError(name, "Undefined property '${name.lexeme}'.");
  }

  void set(Token name, Object value) =>
      _fields.putIfAbsent(name.lexeme, () => value);
}
