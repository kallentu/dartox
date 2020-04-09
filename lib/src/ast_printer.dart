import 'package:dartox/src/expr.dart';
import 'package:dartox/src/token.dart';
import 'package:dartox/src/token_type.dart';

class AstPrinter extends ExprVisitor<String> {
  String print(Expr expr) {
    return expr.accept(this);
  }

  @override
  String visitBinaryExpr(Binary expr) {
    return _parenthesize(expr.operator.lexeme, [expr.left, expr.right]);
  }

  @override
  String visitGroupingExpr(Grouping expr) {
    return _parenthesize("group", [expr.expression]);
  }

  @override
  String visitLiteralExpr(Literal expr) {
    if (expr.value == null) return "nil";
    return expr.value.toString();
  }

  @override
  String visitUnaryExpr(Unary expr) {
    return _parenthesize(expr.operator.lexeme, [expr.right]);
  }

  String _parenthesize(String name, List<Expr> expressions) {
    String contents = "(" + name;
    for (Expr expr in expressions) {
      contents += " ";
      contents += expr.accept(this);
    }
    contents += ")";
    return contents;
  }
}
