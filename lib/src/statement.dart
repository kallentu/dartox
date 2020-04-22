import 'package:dartox/src/expr.dart';
import 'package:dartox/src/token.dart';

abstract class Statement {
  R accept<R>(StatementVisitor<R> visitor);
}

abstract class StatementVisitor<R> {
  R visitBlockStatement(Block statement);
  R visitBreakStatement(Break statement);
  R visitContinueStatement(Continue statement);
  R visitExpressionStatement(Expression statement);
  R visitForStatement(For statement);
  R visitIfStatement(If statement);
  R visitPrintStatement(Print statement);
  R visitVarStatement(Var statement);
  R visitWhileStatement(While statement);
}

class Block extends Statement {
  final List<Statement> statements;
  Block(this.statements);
  @override
  R accept<R>(StatementVisitor<R> visitor) {
    return visitor.visitBlockStatement(this);
  }
}

class Break extends Statement {
  Break();
  @override
  R accept<R>(StatementVisitor<R> visitor) {
    return visitor.visitBreakStatement(this);
  }
}

class Continue extends Statement {
  Continue();
  @override
  R accept<R>(StatementVisitor<R> visitor) {
    return visitor.visitContinueStatement(this);
  }
}

class Expression extends Statement {
  final Expr expression;
  Expression(this.expression);
  @override
  R accept<R>(StatementVisitor<R> visitor) {
    return visitor.visitExpressionStatement(this);
  }
}

class For extends Statement {
  final Expr condition;
  final Statement body;
  final Expression increment;
  For(this.condition, this.body, this.increment);
  @override
  R accept<R>(StatementVisitor<R> visitor) {
    return visitor.visitForStatement(this);
  }
}

class If extends Statement {
  final Expr condition;
  final Statement thenBranch;
  final Statement elseBranch;
  If(this.condition, this.thenBranch, this.elseBranch);
  @override
  R accept<R>(StatementVisitor<R> visitor) {
    return visitor.visitIfStatement(this);
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

class While extends Statement {
  final Expr condition;
  final Statement body;
  While(this.condition, this.body);
  @override
  R accept<R>(StatementVisitor<R> visitor) {
    return visitor.visitWhileStatement(this);
  }
}
