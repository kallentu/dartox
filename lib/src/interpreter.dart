import 'package:dartox/src/environment.dart';
import 'package:dartox/src/error.dart';
import 'package:dartox/src/expr.dart';
import 'package:dartox/src/runtime_error.dart';
import 'package:dartox/src/statement.dart';
import 'package:dartox/src/token.dart';
import 'package:dartox/src/token_type.dart';

class Interpreter implements ExprVisitor<Object>, StatementVisitor<void> {
  final ErrorReporter _errorReporter;
  Environment _environment = Environment();

  Interpreter(this._errorReporter);

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
  Object visitGroupingExpr(Grouping expr) => _evaluate(expr.expression);

  @override
  Object visitLiteralExpr(Literal expr) => expr.value;

  @override
  Object visitTernaryExpr(Ternary expr) {
    Object boolValue = _evaluate(expr.value);
    Object left = _evaluate(expr.left);
    Object right = _evaluate(expr.right);

    // Pre-runtime checks to prevent runtime errors.
    _checkNumberOperands(expr.operator2, [left, right]);

    // Only ternary expression is ?:
    if (expr.operator1.type == TokenType.QUESTION &&
        expr.operator2.type == TokenType.COLON) {
      return _isTruthy(boolValue) ? left : right;
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
  void visitPrintStatement(Print statement) =>
      print(_stringify(_evaluate(statement.expression)));

  @override
  void visitVarStatement(Var statement) {
    // Evaluate the initial value and assign it in the environment.
    Object value =
        statement.initializer != null ? _evaluate(statement.initializer) : null;
    _environment.define(statement.name.lexeme, value);
  }

  @override
  Object visitVariableExpr(Variable expr) => _environment.get(expr.name);

  @override
  Object visitAssignExpr(Assign expr) {
    Object value = _evaluate(expr.value);
    _environment.assign(expr.name, value);
    return value;
  }

  @override
  void visitBlockStatement(Block statement) => _executeBlock(
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
  void _executeBlock(List<Statement> statements, Environment environment) {
    Environment previous = _environment;
    try {
      _environment = environment;
      for (Statement statement in statements) {
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
