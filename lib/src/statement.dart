import 'package:dartox/src/expr.dart';

abstract class Statement {
  R accept<R>(StatementVisitor<R> visitor);
}

abstract class StatementVisitor<R> {
  R visitExpressionStatement(Expression statement);
  R visitPrintStatement(Print statement);
}

class Expression extends Statement {
  final Expr expression;
  Expression(this.expression);
  @override
  R accept<R>(StatementVisitor<R> visitor) {
    return visitor.visitExpressionStatement(this);
  }
}

class Print extends Statement {
  final Expr expression;
  Print(this.expression);
  @override
  R accept<R>(StatementVisitor<R> visitor) {
    return visitor.visitPrintStatement(this);
  }
}
