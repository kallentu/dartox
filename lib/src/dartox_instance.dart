import 'package:dartox/src/dartox_class.dart';

/// Runtime representation of an instance of a Dartox class.
class DartoxInstance {
  DartoxClass _clas;

  DartoxInstance(this._clas);

  @override
  String toString() => _clas.name + " instance";
}
