import 'dart:collection';

import 'package:dartox/core/stack.dart';
import 'package:dartox/src/error.dart';
import 'package:dartox/src/expr.dart';
import 'package:dartox/src/interpreter.dart';
import 'package:dartox/src/statement.dart';
import 'package:dartox/src/token.dart';

class Resolver implements ExprVisitor<void>, StatementVisitor<void> {
  final Interpreter _interpreter;

  /// Only used for local stacks. Global variables are not tracked by resolver.
  /// If we cannot find in the stack of scopes, it must be global.
  ///
  /// Each element is a Map which is a single block scope.
  /// <String, bool> is <variable-names, is-ready>
  /// If false, not finished being initialized.
  final Stack<HashMap<String, bool>> _scopes = Stack();

  final ErrorReporter _errorReporter;

  Resolver(this._interpreter, this._errorReporter);

  void resolveStatements(List<Statement> statements) {
    for (Statement statement in statements) {
      _resolveStatement(statement);
    }
  }

  @override
  void visitBlockStatement(Block statement) {
    _beginScope();
    resolveStatements(statement.statements);
    _endScope();
  }

  @override
  void visitBreakStatement(Break statement) => null;

  @override
  void visitContinueStatement(Continue statement) => null;

  @override
  void visitExpressionStatement(Expression statement) =>
      _resolveExpr(statement.expression);

  @override
  void visitForStatement(For statement) {
    _resolveExpr(statement.condition);
    _resolveStatement(statement.body);
  }

  @override
  void visitFunctionStatement(Function statement) {
    // Eagerly binds name of function to allow for recursion.
    _declare(statement.name);
    _define(statement.name);

    // Introduces a scope and bind its parameters into that scope.
    _resolveFunction(statement);
  }

  @override
  void visitIfStatement(If statement) {
    _resolveExpr(statement.condition);
    _resolveStatement(statement.thenBranch);
    if (statement.elseBranch != null) _resolveStatement(statement.elseBranch);
  }

  @override
  void visitPrintStatement(Print statement) => null;

  @override
  void visitReturnStatement(Return statement) {
    if (statement.value != null) {
      _resolveExpr(statement.value);
    }
  }

  @override
  void visitVarStatement(Var statement) {
    _declare(statement.name);
    if (statement.initializer != null) {
      _resolveExpr(statement.initializer);
    }
    _define(statement.name);
  }

  @override
  void visitWhileStatement(While statement) {
    _resolveExpr(statement.condition);
    _resolveStatement(statement.body);
  }

  @override
  void visitAnonFunctionExpr(AnonFunction function) {
    _beginScope();
    for (Token parameter in function.params) {
      _declare(parameter);
      _define(parameter);
    }
    resolveStatements(function.body);
    _endScope();
  }

  @override
  void visitAssignExpr(Assign expr) {
    // First, resolve expression for assigned value in case it references other
    // variables.
    _resolveExpr(expr.value);
    _resolveLocal(expr, expr.name);
  }

  @override
  void visitBinaryExpr(Binary expr) {
    _resolveExpr(expr.left);
    _resolveExpr(expr.right);
  }

  @override
  void visitCallExpr(Call expr) {
    _resolveExpr(expr.callee);

    for (Expr arg in expr.arguments) {
      _resolveExpr(arg);
    }
  }

  @override
  void visitGroupingExpr(Grouping expr) => _resolveExpr(expr.expression);

  /// Literals have no variables, no subexpressions so there's no resolving.
  @override
  void visitLiteralExpr(Literal expr) => null;

  @override
  void visitLogicalExpr(Logical expr) {
    _resolveExpr(expr.left);
    _resolveExpr(expr.right);
  }

  @override
  void visitTernaryExpr(Ternary expr) {
    _resolveExpr(expr.value);
    _resolveExpr(expr.left);
    _resolveExpr(expr.right);
  }

  @override
  void visitUnaryExpr(Unary expr) => _resolveExpr(expr.right);

  @override
  void visitVariableExpr(Variable expr) {
    if (!_scopes.isEmpty && _scopes.peek()[expr.name.lexeme] == false) {
      // Declared, but not defined. Error.
      _errorReporter.tokenError(
          expr.name, "Cannot read local variable in its own initializer");
    }
    _resolveLocal(expr, expr.name);
  }

  void _resolveStatement(Statement statement) => statement.accept(this);

  void _resolveExpr(Expr expr) => expr.accept(this);

  void _resolveLocal(Expr expr, Token name) {
    for (int i = _scopes.size() - 1; i >= 0; i--) {
      if (_scopes.get(i).containsKey(name.lexeme)) {
        _interpreter.resolve(expr, _scopes.size() - 1 - i);
        return;
      }
    }

    // Not found. Assume it is global.
  }

  /// Creates a new scope and binds variables for each of the parameters.
  void _resolveFunction(Function function) {
    _beginScope();
    for (Token parameter in function.params) {
      _declare(parameter);
      _define(parameter);
    }
    resolveStatements(function.body);
    _endScope();
  }

  void _beginScope() => _scopes.push(new HashMap<String, bool>());

  void _endScope() => _scopes.pop();

  void _declare(Token name) {
    if (_scopes.isEmpty) return;

    HashMap<String, bool> scope = _scopes.peek();
    scope.putIfAbsent(name.lexeme, () => false);
  }

  void _define(Token name) {
    if (_scopes.isEmpty) return;
    _scopes.peek().putIfAbsent(name.lexeme, () => true);
  }
}
