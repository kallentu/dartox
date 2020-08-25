import 'package:dartox/src/expr.dart';
import 'package:dartox/src/token.dart';

abstract class Statement {
  R accept<R>(StatementVisitor<R> visitor);
}

abstract class StatementVisitor<R> {
  R visitBlockStatement(Block statement);
  R visitBreakStatement(Break statement);
  R visitClassStatement(Class statement);
  R visitContinueStatement(Continue statement);
  R visitExpressionStatement(Expression statement);
  R visitFunctionStatement(Function statement);
  R visitForStatement(For statement);
  R visitGetterStatement(Getter statement);
  R visitIfStatement(If statement);
  R visitPrintStatement(Print statement);
  R visitReturnStatement(Return statement);
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
  final Token keyword;
  Break(this.keyword);
  @override
  R accept<R>(StatementVisitor<R> visitor) {
    return visitor.visitBreakStatement(this);
  }
}

class Class extends Statement {
  final Token name;
  final Variable superclass;
  final List<Function> methods;
  final List<Function> staticMethods;
  final List<Getter> getters;
  Class(this.name, this.superclass, this.methods, this.staticMethods, this.getters);
  @override
  R accept<R>(StatementVisitor<R> visitor) {
    return visitor.visitClassStatement(this);
  }
}

class Continue extends Statement {
  final Token keyword;
  Continue(this.keyword);
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

class Function extends Statement {
  final Token name;
  final List<Token> params;
  final List<Statement> body;
  Function(this.name, this.params, this.body);
  Function.withNoName(this.params, this.body) : name = null;
  @override
  R accept<R>(StatementVisitor<R> visitor) {
    return visitor.visitFunctionStatement(this);
  }
}

class For extends Statement {
  final Statement init;
  final Expr condition;
  final Statement body;
  final Expression increment;
  For(this.init, this.condition, this.body, this.increment);
  @override
  R accept<R>(StatementVisitor<R> visitor) {
    return visitor.visitForStatement(this);
  }
}

class Getter extends Statement {
  final Token name;
  final List<Statement> body;
  Getter(this.name, this.body);
  @override
  R accept<R>(StatementVisitor<R> visitor) {
    return visitor.visitGetterStatement(this);
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

class Return extends Statement {
  final Token keyword;
  final Expr value;
  Return(this.keyword, this.value);
  @override
  R accept<R>(StatementVisitor<R> visitor) {
    return visitor.visitReturnStatement(this);
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
