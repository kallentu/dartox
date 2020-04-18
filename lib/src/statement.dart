import 'package:dartox/src/expr.dart';
import 'package:dartox/src/token.dart';

abstract class Statement {
  R accept<R>(StatementVisitor<R> visitor);
}

abstract class StatementVisitor<R> {
  R visitExpressionStatement(Expression statement);
  R visitPrintStatement(Print statement);
  R visitVarStatement(Var statement);
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

class Var extends Statement {
  final Token name;
  final Expr initializer;
  Var(this.name, this.initializer);
  @override
  R accept<R>(StatementVisitor<R> visitor) {
    return visitor.visitVarStatement(this);
  }
}
