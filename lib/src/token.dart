import 'package:dartox/src/token_type.dart';

class Token {
  final TokenType type;
  final String lexeme;
  final Object literal;
  final int line;

  Token(this.type, this.lexeme, this.literal, this.line);

  @override
  String toString() => "$type $lexeme $literal";
}
