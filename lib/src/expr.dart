import 'package:dartox/src/token.dart';
import 'package:dartox/src/statement.dart';

abstract class Expr {
  R accept<R>(ExprVisitor<R> visitor);
}

abstract class ExprVisitor<R> {
  R visitAssignExpr(Assign expr);
  R visitAnonFunctionExpr(AnonFunction expr);
  R visitBinaryExpr(Binary expr);
  R visitCallExpr(Call expr);
  R visitGetExpr(Get expr);
  R visitGroupingExpr(Grouping expr);
  R visitLiteralExpr(Literal expr);
  R visitLogicalExpr(Logical expr);
  R visitSetExpr(Set expr);
  R visitTernaryExpr(Ternary expr);
  R visitThisExpr(This expr);
  R visitUnaryExpr(Unary expr);
  R visitVariableExpr(Variable expr);
}

class Assign extends Expr {
  final Token name;
  final Expr value;
  Assign(this.name, this.value);
  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitAssignExpr(this);
  }
}

class AnonFunction extends Expr {
  final List<Token> params;
  final List<Statement> body;
  AnonFunction(this.params, this.body);
  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitAnonFunctionExpr(this);
  }
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

class Call extends Expr {
  final Expr callee;
  final Token paren;
  final List<Expr> arguments;
  Call(this.callee, this.paren, this.arguments);
  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitCallExpr(this);
  }
}

class Get extends Expr {
  final Expr object;
  final Token name;
  Get(this.object, this.name);
  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitGetExpr(this);
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

class Logical extends Expr {
  final Expr left;
  final Token operator;
  final Expr right;
  Logical(this.left, this.operator, this.right);
  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitLogicalExpr(this);
  }
}

class Set extends Expr {
  final Expr object;
  final Token name;
  final Expr value;
  Set(this.object, this.name, this.value);
  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitSetExpr(this);
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

class This extends Expr {
  final Token keyword;
  This(this.keyword);
  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitThisExpr(this);
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

class Variable extends Expr {
  final Token name;
  Variable(this.name);
  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitVariableExpr(this);
  }
}
