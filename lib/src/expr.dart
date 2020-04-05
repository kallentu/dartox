import 'package:dartox/src/token.dart';

abstract class Expr {}

class Binary extends Expr {
  final Expr left;
  final Token operator;
  final Expr right;
  Binary(this.left, this.operator, this.right);
}

class Grouping extends Expr {
  final Expr expression;
  Grouping(this.expression);
}

class Literal extends Expr {
  final Object value;
  Literal(this.value);
}

class Unary extends Expr {
  final Token operator;
  final Expr right;
  Unary(this.operator, this.right);
}
