import 'package:dartox/src/token.dart';

abstract class Expr {
  R accept<R>(ExprVisitor<R> visitor);
}

abstract class ExprVisitor<R> {
  R visitBinaryExpr(Binary expr);
  R visitTernaryExpr(Ternary expr);
  R visitGroupingExpr(Grouping expr);
  R visitLiteralExpr(Literal expr);
  R visitUnaryExpr(Unary expr);
}

class Binary extends Expr {
  final Expr left;
  final Token operator;
  final Expr right;
  Binary(this.left, this.operator, this.right);
  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitBinaryExpr(this);
  }
}

class Ternary extends Expr {
  final Expr value;
  final Token operator1;
  final Expr left;
  final Token operator2;
  final Expr right;
  Ternary(this.value, this.operator1, this.left, this.operator2, this.right);
  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitTernaryExpr(this);
  }
}

class Grouping extends Expr {
  final Expr expression;
  Grouping(this.expression);
  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitGroupingExpr(this);
  }
}

class Literal extends Expr {
  final Object value;
  Literal(this.value);
  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitLiteralExpr(this);
  }
}

class Unary extends Expr {
  final Token operator;
  final Expr right;
  Unary(this.operator, this.right);
  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitUnaryExpr(this);
  }
}
