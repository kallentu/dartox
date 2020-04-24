import 'package:dartox/src/dartox_callable.dart';
import 'package:dartox/src/dartox_function.dart';
import 'package:dartox/src/environment.dart';
import 'package:dartox/src/error.dart';
import 'package:dartox/src/expr.dart';
import 'package:dartox/src/return.dart';
import 'package:dartox/src/runtime_error.dart';
import 'package:dartox/src/statement.dart';
import 'package:dartox/src/token.dart';
import 'package:dartox/src/token_type.dart';

class Interpreter implements ExprVisitor<Object>, StatementVisitor<void> {
  final ErrorReporter _errorReporter;

  /// The outermost global environment.
  final Environment globals = Environment();

  /// The current environment.
  Environment _environment;

  Interpreter(this._errorReporter) {
    _environment = globals;
    globals.define("clock", ClockCallable());
  }

  void interpret(List<Statement> statements) {
    try {
      for (Statement statement in statements) {
        _execute(statement);
      }
    } catch (e) {
      if (e is RuntimeError) _errorReporter.runtimeError(e);
    }
  }

  @override
  Object visitBinaryExpr(Binary expr) {
    Object left = _evaluate(expr.left);
    Object right = _evaluate(expr.right);

    switch (expr.operator.type) {
      case TokenType.GREATER:
        _checkNumberOperands(expr.operator, [right]);
        return (left as double) > (right as double);
      case TokenType.GREATER_EQUAL:
        _checkNumberOperands(expr.operator, [right]);
        return (left as double) >= (right as double);
      case TokenType.LESS:
        _checkNumberOperands(expr.operator, [right]);
        return (left as double) < (right as double);
      case TokenType.LESS_EQUAL:
        _checkNumberOperands(expr.operator, [right]);
        return (left as double) <= (right as double);
      case TokenType.BANG_EQUAL:
        _checkNumberOperands(expr.operator, [right]);
        return !_isEqual(left, right);
      case TokenType.EQUAL_EQUAL:
        _checkNumberOperands(expr.operator, [right]);
        return _isEqual(left, right);
      case TokenType.MINUS:
        _checkNumberOperands(expr.operator, [right]);
        return (left as double) - (right as double);
      case TokenType.PLUS:
        if (left is double && right is double) {
          return left + right;
        } else if (left is String && right is String) {
          return left + right;
        } else if (left is String || right is String) {
          // Additional case where if either operand is a string,
          // convert both to a string and concatenate.
          return _stringify(left) + _stringify(right);
        }
        // Unreachable for values of PLUS.
        throw new RuntimeError(
            expr.operator, "Operands must be two numbers or two strings.");
      case TokenType.SLASH:
        if (right == 0)
          throw new RuntimeError(expr.operator, "Divisor cannot be zero.");
        return (left as double) / (right as double);
      case TokenType.STAR:
        return (left as double) * (right as double);
      default:
        // Unreachable.
        return null;
    }
  }

  @override
  Object visitCallExpr(Call expr) {
    Object callee = _evaluate(expr.callee);

    List<Object> arguments = List();
    for (Expr arg in expr.arguments) {
      arguments.add(_evaluate(arg));
    }

    // Must actually be a callable function.
    if (callee is DartoxCallable) {
      // Check arity is correct.
      if (arguments.length != callee.arity()) {
        throw RuntimeError(
            expr.paren,
            "Expected " +
                callee.arity().toString() +
                " arguments, but got " +
                arguments.length.toString() +
                ".");
      }

      return callee.call(this, arguments);
    } else {
      throw RuntimeError(expr.paren, "Can only call functions and classes.");
    }
  }

  @override
  Object visitGroupingExpr(Grouping expr) => _evaluate(expr.expression);

  @override
  Object visitLiteralExpr(Literal expr) => expr.value;

  @override
  Object visitLogicalExpr(Logical expr) {
    Object left = _evaluate(expr.left);

    if (expr.operator.type == TokenType.OR) {
      // Return true immediately, breaks OR.
      if (_isTruthy(left)) return left;
    } else {
      // TokenType.AND
      // Return false immediately, breaks AND.
      if (!_isTruthy(left)) return left;
    }

    return _evaluate(expr.right);
  }

  @override
  Object visitTernaryExpr(Ternary expr) {
    // Only ternary expression is ?:
    if (expr.operator1.type == TokenType.QUESTION &&
        expr.operator2.type == TokenType.COLON) {
      return _isTruthy(_evaluate(expr.value))
          ? _evaluate(expr.left)
          : _evaluate(expr.right);
    }

    // Unreachable.
    return null;
  }

  @override
  Object visitUnaryExpr(Unary expr) {
    Object right = _evaluate(expr.right);

    switch (expr.operator.type) {
      case TokenType.BANG:
        return !_isTruthy(right);
      case TokenType.MINUS:
        _checkNumberOperands(expr.operator, [right]);
        return -(right as double);
      default:
        // Unreachable
        return null;
    }
  }

  @override
  void visitExpressionStatement(Expression statement) =>
      _evaluate(statement.expression);

  @override
  void visitFunctionStatement(Function statement) =>
      _environment.define(statement.name.lexeme, DartoxFunction(statement));

  @override
  void visitIfStatement(If statement) {
    if (_isTruthy(_evaluate(statement.condition))) {
      _execute(statement.thenBranch);
    } else if (statement.elseBranch != null) {
      _execute(statement.elseBranch);
    }
  }

  @override
  void visitPrintStatement(Print statement) =>
      print(_stringify(_evaluate(statement.expression)));

  @override
  void visitReturnStatement(Return statement) {
    Object value = statement.value != null ? _evaluate(statement.value) : null;
    throw ReturnException(value);
  }

  @override
  void visitVarStatement(Var statement) {
    // Evaluate the initial value and assign it in the environment.
    Object value =
        statement.initializer != null ? _evaluate(statement.initializer) : null;
    _environment.define(statement.name.lexeme, value);
  }

  @override
  void visitWhileStatement(While statement) {
    // Set loop environment to ensure we can break and continue inside this.
    _environment.isLoopEnvironment = true;

    // Will continue to run until condition is not true or when a break
    // statement is hit.
    while (
        _isTruthy(_evaluate(statement.condition)) && !_environment.isBroken()) {
      if (_environment.isContinued()) {
        // Continues only activate once per loop iteration, must reset for next
        // iteration.
        _environment.setContinued(false);
        continue;
      }
      _execute(statement.body);
    }
  }

  @override
  void visitForStatement(For statement) {
    // Set loop environment to ensure we can break and continue inside this.
    _environment.isLoopEnvironment = true;

    // Will continue to run until condition is not true or when a break
    // statement is hit.
    while (
        _isTruthy(_evaluate(statement.condition)) && !_environment.isBroken()) {
      if (_environment.isContinued()) {
        // Continues only activate once per loop iteration, must reset for next
        // iteration.
        _environment.setContinued(false);
        continue;
      }
      _execute(statement.body);

      // Increment is separate when we use a break/continue.
      // We will still execute this.
      _execute(statement.increment);
    }
  }

  @override
  void visitBreakStatement(Break statement) => _environment.setBroken(true);

  @override
  void visitContinueStatement(Continue statement) =>
      _environment.setContinued(true);

  @override
  Object visitVariableExpr(Variable expr) => _environment.get(expr.name);

  @override
  Object visitAssignExpr(Assign expr) {
    Object value = _evaluate(expr.value);
    _environment.assign(expr.name, value);
    return value;
  }

  @override
  void visitBlockStatement(Block statement) => executeBlock(
      statement.statements, Environment.withEnclosing(_environment));

  void _checkNumberOperands(Token operator, List<Object> operands) {
    if (operands.every((e) => e is double)) return;
    throw new RuntimeError(operator, "Operand(s) must be a number.");
  }

  /// Determines the value of the expression given.
  Object _evaluate(Expr expr) => expr.accept(this);

  /// Execute the behaviour of the statement given.
  void _execute(Statement statement) => statement.accept(this);

  /// Updates to execute with the current environment, innermost scope.
  void executeBlock(List<Statement> statements, Environment environment) {
    Environment previous = _environment;
    try {
      _environment = environment;
      for (Statement statement in statements) {
        // Stop executing other statements if we have a continue/break.
        if (_environment.isBroken()) {
          previous.setBroken(true);
          break;
        } else if (_environment.isContinued()) {
          previous.setContinued(true);
          break;
        }
        _execute(statement);
      }
    } finally {
      _environment = previous;
    }
  }

  bool _isTruthy(Object object) {
    if (object == null) return false;
    if (object is bool) return object;
    return true;
  }

  bool _isEqual(Object a, Object b) {
    // nil is only equal to nil
    if (a == null && b == null) return true;
    return a == b;
  }

  String _stringify(Object object) {
    if (object == null) return "nil";

    // Hack. Work around the adding of ".0" for integer doubles.
    if (object is double) {
      String text = object.toString();
      if (text.endsWith(".0")) {
        text = text.substring(0, text.length - 2);
      }
      return text;
    }

    return object.toString();
  }
}
