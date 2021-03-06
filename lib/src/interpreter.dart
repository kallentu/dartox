import 'dart:collection';

import 'package:dartox/src/dartox_callable.dart';
import 'package:dartox/src/dartox_class.dart';
import 'package:dartox/src/dartox_function.dart';
import 'package:dartox/src/dartox_getter.dart';
import 'package:dartox/src/dartox_instance.dart';
import 'package:dartox/src/environment.dart';
import 'package:dartox/src/error.dart';
import 'package:dartox/src/expr.dart';
import 'package:dartox/src/exception.dart';
import 'package:dartox/src/runtime_error.dart';
import 'package:dartox/src/statement.dart';
import 'package:dartox/src/token.dart';
import 'package:dartox/src/token_type.dart';

class Interpreter implements ExprVisitor<Object>, StatementVisitor<void> {
  final ErrorReporter _errorReporter;

  /// The outermost global environment.
  final Environment globals = Environment();

  /// Number of environments between current and enclosing one where we can find
  /// the value of our Expr.
  final HashMap<Expr, int> locals = HashMap();

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
  Object visitAnonFunctionExpr(AnonFunction anonFunction) => DartoxFunction(
      Function.withNoName(anonFunction.params, anonFunction.body),
      _environment,
      false);

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
  Object visitGetExpr(Get expr) {
    Object object = _evaluate(expr.object);
    if (object is DartoxInstance) {
      Object value = object.get(expr.name);

      // Must execute the block if getter value.
      return value is DartoxGetter ? value.execute(this) : value;
    }

    throw RuntimeError(expr.name, "Only instances have properties.");
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
  Object visitSetExpr(Set expr) {
    Object object = _evaluate(expr.object);

    if (!(object is DartoxInstance)) {
      throw RuntimeError(expr.name, "Only instances have fields.");
    }

    Object value = _evaluate(expr.value);
    (object as DartoxInstance).set(expr.name, value);
    return value;
  }

  /// Essentially the code for looking up a method in a getter,
  /// except findMethod is on the superclass.
  @override
  Object visitSuperExpr(Super expr) {
    // We look up "super" to find it in the proper environment.
    int distance = locals[expr];
    DartoxClass superclass = _environment.getAt(distance, "super");

    // "this" is always one level nearer than "super"'s environment.
    DartoxInstance thisInstance = _environment.getAt(distance - 1, "this");

    // Lastly, bind the method to "this".
    DartoxFunction method = superclass.findMethod(expr.method.lexeme);

    if (method == null) {
      throw RuntimeError(
          expr.method, "Undefined property '" + expr.method.lexeme + "'.");
    }

    return method.bind(thisInstance);
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
  Object visitThisExpr(This expr) => _lookUpVariable(expr.keyword, expr);

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
  void visitFunctionStatement(Function statement) => _environment.define(
      statement.name.lexeme, DartoxFunction(statement, _environment, false));

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
    // Will continue to run until condition is not true or when a break
    // statement is hit.
    while (_isTruthy(_evaluate(statement.condition))) {
      try {
        _execute(statement.body);
      } catch (e) {
        if (e is BreakException) {
          // Break out of visiting for loop.
          break;
        } else if (e is ContinueException) {
          // Continues only activate once per loop iteration,
          // must reset for next iteration.
          continue;
        } else {
          throw e;
        }
      }
    }
  }

  @override
  void visitForStatement(For statement) {
    _execute(statement.init);

    // Will continue to run until condition is not true or when a break
    // statement is hit.
    while (_isTruthy(_evaluate(statement.condition))) {
      try {
        _execute(statement.body);
      } catch (e) {
        if (e is BreakException) {
          // Break out of visiting for loop.
          break;
        } else if (e is ContinueException) {
          // Continues only activate once per loop iteration,
          // must reset for next iteration.
          continue;
        } else {
          throw e;
        }
      } finally {
        // Increment is separate when we use a break/continue.
        // We will still execute this.
        _execute(statement.increment);
      }
    }
  }

  @override
  void visitGetterStatement(Getter statement) =>
      executeBlock(statement.body, Environment.withEnclosing(_environment));

  @override
  void visitBreakStatement(Break statement) => throw BreakException();

  @override
  void visitClassStatement(Class statement) {
    Object superclass = null;
    if (statement.superclass != null) {
      superclass = _evaluate(statement.superclass);
      if (!(superclass is DartoxClass)) {
        throw new RuntimeError(
            statement.superclass.name, "Superclass must be a class.");
      }
    }

    _environment.define(statement.name.lexeme, null);

    // Create new environment for superclass.
    // Store the reference for the superclass.
    if (statement.superclass != null) {
      _environment = Environment.withEnclosing(_environment);
      _environment.define("super", superclass);
    }

    // Turn each of the class methods into its runtime representation.
    // If we have a super class, the DartoxFunctions will be captured by
    // the environment that holds the "super" in their closure so they
    // can use it.
    Map<String, DartoxFunction> methods = HashMap();
    for (Function method in statement.methods) {
      DartoxFunction function =
          DartoxFunction(method, _environment, method.name.lexeme == "init");
      methods.putIfAbsent(method.name.lexeme, () => function);
    }

    Map<Token, DartoxFunction> staticMethods = HashMap();
    for (Function method in statement.staticMethods) {
      DartoxFunction function = DartoxFunction(method, _environment, false);
      staticMethods.putIfAbsent(method.name, () => function);
    }

    Map<Token, DartoxGetter> getters = HashMap();
    for (Getter getter in statement.getters) {
      DartoxGetter getterRuntime = DartoxGetter(getter, _environment);
      getters.putIfAbsent(getter.name, () => getterRuntime);
    }

    DartoxClass clas = DartoxClass(statement.name.lexeme,
        superclass as DartoxClass, methods, staticMethods, getters);

    // Pop the environment for the methods (that need super) and use the
    // previous one.
    if (superclass != null) {
      _environment = _environment.enclosing;
    }

    _environment.assign(statement.name, clas);
  }

  @override
  void visitContinueStatement(Continue statement) => throw ContinueException();

  @override
  Object visitVariableExpr(Variable expr) => _lookUpVariable(expr.name, expr);

  Object _lookUpVariable(Token name, Expr expr) {
    // No distance means global variable.
    int distance = locals[expr];
    return distance != null
        ? _environment.getAt(distance, name.lexeme)
        : globals.get(name);
  }

  @override
  Object visitAssignExpr(Assign expr) {
    Object value = _evaluate(expr.value);
    int distance = locals[expr];
    if (distance != null) {
      _environment.assignAt(distance, expr.name, value);
    } else {
      globals.assign(expr.name, value);
    }

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

  /// Each expression node is its own Expr object, so this will be fine to
  /// keep them unique.
  void resolve(Expr expr, int depth) => locals.putIfAbsent(expr, () => depth);

  /// Updates to execute with the current environment, innermost scope.
  void executeBlock(List<Statement> statements, Environment environment) {
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
