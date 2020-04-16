import 'package:dartox/src/expr.dart';
import 'package:dartox/src/token_type.dart';

class Interpreter implements ExprVisitor<Object> {
  @override
  Object visitBinaryExpr(Binary expr) {
    Object left = _evaluate(expr.left);
    Object right = _evaluate(expr.right);

    switch (expr.operator.type) {
      case TokenType.GREATER:
        return (left as double) > (right as double);
      case TokenType.GREATER_EQUAL:
        return (left as double) >= (right as double);
      case TokenType.LESS:
        return (left as double) < (right as double);
      case TokenType.LESS_EQUAL:
        return (left as double) <= (right as double);
      case TokenType.BANG_EQUAL:
        return !_isEqual(left, right);
      case TokenType.EQUAL_EQUAL:
        return _isEqual(left, right);
      case TokenType.MINUS:
        return (left as double) - (right as double);
      case TokenType.PLUS:
        if (left is double && right is double) {
          return left + right;
        } else if (left is String && right is String) {
          return left + right;
        }
        // Unreachable for values of PLUS.
        return null;
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

    // Only ternary expression is ?:
    if (expr.operator1.type == TokenType.QUESTION && expr.operator2.type == TokenType.COLON) {
      if (boolValue as bool) {
        // [boolValue] true, return left.
        return left;
      } else {
        // [boolValue] false, return right.
        return right;
      }
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
        return -(right as double);
      default:
        // Unreachable
        return null;
    }
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
}