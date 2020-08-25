import 'package:dartox/src/expr.dart';
import 'package:dartox/src/statement.dart';
import 'package:dartox/src/token.dart';

class AstPrinter extends ExprVisitor<String> {
  String print(Expr expr) {
    return expr.accept(this);
  }

  @override
  String visitAnonFunctionExpr(AnonFunction expr) {
    String contents = "fun (";

    for (Token param in expr.params) {
      contents += param.lexeme + ", ";
    }

    // Remove last comma.
    contents = contents.substring(0, contents.length - 2) + ") {\n";

    for (Statement statement in expr.body) {
      contents += statement.toString() + "\n";
    }

    return contents + "}";
  }

  @override
  String visitBinaryExpr(Binary expr) =>
      _parenthesize([expr.operator.lexeme], [expr.left, expr.right]);

  @override
  String visitCallExpr(Call expr) {
    String contents = expr.callee.accept(this) + "(";
    for (Expr arg in expr.arguments) {
      contents += arg.accept(this) + ", ";
    }
    return contents.substring(0, contents.length - 2) + ")";
  }

  @override
  String visitGetExpr(Get expr) => print(expr.object) + ".${expr.name}";

  @override
  String visitGroupingExpr(Grouping expr) =>
      _parenthesize(["group"], [expr.expression]);

  @override
  String visitLiteralExpr(Literal expr) {
    if (expr.value == null) return "nil";
    return expr.value.toString();
  }

  @override
  String visitLogicalExpr(Logical expr) =>
      expr.left.accept(this) +
      expr.operator.toString() +
      expr.right.accept(this);

  @override
  String visitSetExpr(Set expr) =>
      "${print(expr.object)}.${expr.name.lexeme} = ${expr.value}";

  @override
  String visitTernaryExpr(Ternary expr) => _parenthesize(
      [expr.operator1.lexeme, expr.operator2.lexeme],
      [expr.value, expr.left, expr.right]);

  @override
  String visitThisExpr(This expr) => "this";

  @override
  String visitUnaryExpr(Unary expr) =>
      _parenthesize([expr.operator.lexeme], [expr.right]);

  @override
  String visitVariableExpr(Variable expr) => expr.name.toString();

  @override
  String visitAssignExpr(Assign expr) =>
      expr.name.toString() + " = " + expr.value.toString();

  @override
  String visitSuperExpr(Super expr) =>
      expr.keyword.lexeme + '.' + expr.method.lexeme;

  String _parenthesize(List<String> names, List<Expr> expressions) {
    String contents = "(";
    for (String name in names) {
      contents += " " + name;
    }

    for (Expr expr in expressions) {
      contents += " ";
      contents += expr.accept(this);
    }
    contents += ")";
    return contents;
  }
}
