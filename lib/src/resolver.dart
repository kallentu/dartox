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
  /// <Token, <bool, bool>> is <variable-token, <is-ready, was-used>>
  /// If false, not finished being initialized.
  final Stack<HashMap<Token, ScopeInfo>> _scopes = Stack();

  FunctionType _currentFunction = FunctionType.NONE;
  LoopType _currentLoop = LoopType.NONE;

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
  void visitBreakStatement(Break statement) {
    if (_currentLoop == LoopType.NONE) {
      _errorReporter.tokenError(
          statement.keyword, "Cannot break when not in a loop.");
    }
  }

  @override
  void visitClassStatement(Class statement) {
    _declare(statement.name);
    _define(statement.name);

    // Resolve the methods in the class.
    for (Function method in statement.methods) {
      FunctionType declaration = FunctionType.METHOD;
      _resolveFunction(method, declaration);
    }
  }

  @override
  void visitContinueStatement(Continue statement) {
    if (_currentLoop == LoopType.NONE) {
      _errorReporter.tokenError(
          statement.keyword, "Cannot continue when not in a loop.");
    }
  }

  @override
  void visitExpressionStatement(Expression statement) =>
      _resolveExpr(statement.expression);

  @override
  void visitForStatement(For statement) {
    // Hoist the variable init/assignment out of scope for loop usage.
    _resolveStatement(statement.init);

    // Set loop type when we enter a scope, then reset when we leave the scope.
    LoopType enclosingLoop = _currentLoop;
    _currentLoop = LoopType.LOOP;
    _resolveStatement(statement.body);
    _currentLoop = enclosingLoop;

    _resolveExpr(statement.condition);
    _resolveStatement(statement.increment);
  }

  @override
  void visitFunctionStatement(Function statement) {
    // Eagerly binds name of function to allow for recursion.
    _declare(statement.name);
    _define(statement.name);

    // Introduces a scope and bind its parameters into that scope.
    _resolveFunction(statement, FunctionType.FUNCTION);
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
    if (_currentFunction == FunctionType.NONE) {
      _errorReporter.tokenError(
          statement.keyword, "Cannot return from top-level code.");
    }

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

    // Set loop type when we enter a scope, then reset when we leave the scope.
    LoopType enclosingLoop = _currentLoop;
    _currentLoop = LoopType.LOOP;
    _resolveStatement(statement.body);
    _currentLoop = enclosingLoop;
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

  /// Since properties are looked up dynamically, they don't get resolved.
  @override
  void visitGetExpr(Get expr) => _resolveExpr(expr.object);

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

  /// Since properties are looked up dynamically, they don't get resolved.
  @override
  void visitSetExpr(Set expr) {
    _resolveExpr(expr.value);
    _resolveExpr(expr.object);
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
    if (!_scopes.isEmpty && _scopes.peek()[expr.name.lexeme].isReady == false) {
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
        // Set variable as used.
        _scopes.get(i)[name.lexeme].wasUsed = true;

        _interpreter.resolve(expr, _scopes.size() - 1 - i);
        return;
      }
    }

    // Not found. Assume it is global.
  }

  /// Creates a new scope and binds variables for each of the parameters.
  void _resolveFunction(Function function, FunctionType type) {
    // Set function type when we enter a scope, then reset when we leave the
    // scope.
    FunctionType enclosingFunction = _currentFunction;
    _currentFunction = type;

    _beginScope();
    for (Token parameter in function.params) {
      _declare(parameter);
      _define(parameter);
    }
    resolveStatements(function.body);
    _endScope();

    _currentFunction = enclosingFunction;
  }

  void _beginScope() => _scopes.push(new HashMap<Token, ScopeInfo>());

  void _endScope() {
    // Variables that were never used in any other part of the code will report
    // an error.
    void checkUnusedVariables(Token name, ScopeInfo scopeInfo) {
      if (!scopeInfo.wasUsed) {
        _errorReporter.tokenError(name, "Variable is unused.");
      }
    }

    _scopes.peek().forEach(checkUnusedVariables);
    _scopes.pop();
  }

  /// The state where the variable is not redefined nor used.
  void _declare(Token name) {
    if (_scopes.isEmpty) return;

    HashMap<Token, ScopeInfo> scope = _scopes.peek();
    if (scope.containsKey(name.lexeme)) {
      // Invalid redeclaration.
      _errorReporter.tokenError(
          name, "Variable with this name is already declared in this scope.");
    }

    scope.putIfAbsent(name, () => ScopeInfo(false, false));
  }

  /// The state where the variable is ready, but not used yet.
  void _define(Token name) {
    if (_scopes.isEmpty) return;
    _scopes.peek().putIfAbsent(name, () => ScopeInfo(true, false));
  }
}

enum FunctionType { NONE, FUNCTION, METHOD }

enum LoopType { NONE, LOOP }

/// Scope information used for the [_scopes] map in [Resolver].
class ScopeInfo {
  bool isReady;
  bool wasUsed;
  ScopeInfo(this.isReady, this.wasUsed);
}
