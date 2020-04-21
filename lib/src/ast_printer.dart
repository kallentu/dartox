import 'package:dartox/src/expr.dart';

class AstPrinter extends ExprVisitor<String> {
  String print(Expr expr) {
    return expr.accept(this);
  }

  @override
  String visitBinaryExpr(Binary expr) =>
      _parenthesize([expr.operator.lexeme], [expr.left, expr.right]);

  @override
  String visitTernaryExpr(Ternary expr) => _parenthesize(
      [expr.operator1.lexeme, expr.operator2.lexeme],
      [expr.value, expr.left, expr.right]);

  @override
  String visitGroupingExpr(Grouping expr) =>
      _parenthesize(["group"], [expr.expression]);

  @override
  String visitLiteralExpr(Literal expr) {
    if (expr.value == null) return "nil";
    return expr.value.toString();
  }

  @override
  String visitUnaryExpr(Unary expr) =>
      _parenthesize([expr.operator.lexeme], [expr.right]);

  @override
  String visitVariableExpr(Variable expr) => expr.name.toString();

  @override
  String visitAssignExpr(Assign expr) =>
      expr.name.toString() + " = " + expr.value.toString();

  @override
  String visitLogicalExpr(Logical expr) =>
      expr.left.toString() + expr.operator.toString() + expr.right.toString();

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
