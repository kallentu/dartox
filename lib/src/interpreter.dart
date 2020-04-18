import 'package:dartox/src/error.dart';
import 'package:dartox/src/expr.dart';
import 'package:dartox/src/runtime_error.dart';
import 'package:dartox/src/token.dart';
import 'package:dartox/src/token_type.dart';

class Interpreter implements ExprVisitor<Object> {
  final ErrorReporter errorReporter;

  Interpreter(this.errorReporter);

  void interpret(Expr expr) {
    try {
      // Evaluates syntax tree and shows it to user.
      Object value = _evaluate(expr);
      print(_stringify(value));
    } catch (e) {
      errorReporter.runtimeError(e);
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
        throw new RuntimeError(expr.operator, "Operands must be two numbers or two strings.");
      case TokenType.SLASH:
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
    if (expr.operator1.type == TokenType.QUESTION && expr.operator2.type == TokenType.COLON) {
      return _isTruthy(boolValue) ? left : right;
    }

    // Unreachable.
    return null;
  }

  @override
  Object visitUnaryExpr(Unary expr) {
    Object right = _evaluate(expr.right);

    switch(expr.operator.type) {
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

  void _checkNumberOperands(Token operator, List<Object> operands) {
    if (operands.every((e) => e is double)) return;
    throw new RuntimeError(operator, "Operand(s) must be a number.");
  }

  Object _evaluate(Expr expr) => expr.accept(this);

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