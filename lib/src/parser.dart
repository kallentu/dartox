import 'package:dartox/src/expr.dart';
import 'package:dartox/src/token.dart';
import 'package:dartox/src/token_type.dart';

class Parser {
  final List<Token> _tokens;
  int _current = 0;

  Parser(this._tokens);

  /// expression → equality
  Expr _expression() => _equality();

  /// equality → comparison ( ( "!=" | "==" ) comparison )*
  Expr _equality() {
    Expr expr = _comparison();

    while (_match([TokenType.BANG_EQUAL, TokenType.EQUAL_EQUAL])) {
      Token operator = _previous();
      Expr right = _comparison();
      expr = Binary(expr, operator, right);
    }

    return expr;
  }

  /// comparison → addition ( ( ">" | ">=" | "<" | "<=" ) addition )*
  Expr _comparison() {
    Expr expr = _addition();

    while(_match([TokenType.GREATER, TokenType.GREATER_EQUAL, TokenType.LESS, TokenType.LESS_EQUAL])) {
      Token operator = _previous();
      Expr right = _addition();
      expr = Binary(expr, operator, right);
    }

    return expr;
  }

  /// addition → multiplication ( ( "-" | "+" ) multiplication )*
  Expr _addition() {
    Expr expr = _multiplication();

    while (_match([TokenType.MINUS, TokenType.PLUS])) {
      Token operator = _previous();
      Expr right = _multiplication();
      expr = Binary(expr, operator, right);
    }

    return expr;
  }

  /// multiplication → unary ( ( "/" | "*" ) unary )*
  Expr _multiplication() {
    Expr expr = _unary();

    while (_match([TokenType.SLASH, TokenType.STAR])) {
      Token operator = _previous();
      Expr right = _unary();
      expr = Binary(expr, operator, right);
    }

    return expr;
  }

  /// unary → ( "!" | "-" ) unary
  ///      | primary
  Expr _unary() {
    if (_match([TokenType.BANG, TokenType.MINUS])) {
      Token operator = _previous();
      Expr right = _unary();
      return Unary(operator, right);
    }

    return _primary();
  }

  /// primary → NUMBER | STRING | "false" | "true" | "nil"
  ///        | "(" expression ")"
  Expr _primary() {
    if (_match([TokenType.FALSE])) return Literal(false);
    if (_match([TokenType.TRUE])) return Literal(true);
    if (_match([TokenType.NIL])) return Literal(null);

    if (_match([TokenType.NUMBER, TokenType.STRING])) {
      return Literal(_previous().literal);
    }

    if (_match([TokenType.LEFT_PAREN])) {
      Expr expr = _expression();
      // TODO: Parser recovery.
      //_consume(TokenType.RIGHT_PAREN, "Expected ')' after expression.");
      return Grouping(expr);
    }
  }

  /// Checks the current token is of given type, consumes token.
  bool _match(List<TokenType> types) {
    for (TokenType type in types) {
      if (_check(type)) {
        _advance();
        return true;
      }
    }

    // Did not match any of the wanted types.
    return false;
  }

  /// Checks the current token is of given type, does not consume token.
  bool _check(TokenType type) {
    if (_isAtEnd()) return false;
    return _peek().type == type;
  }

  /// Moves [current] forward and returns the previous token.
  Token _advance() {
    if (!_isAtEnd()) _current++;
    return _previous();
  }

  /// Check that we are at the end of the input
  bool _isAtEnd() => _peek().type == TokenType.EOF;

  /// Return, but do not consume current token.
  Token _peek() => _tokens.elementAt(_current);

  /// Return, but do not consume previous token.
  Token _previous() => _tokens.elementAt(_current - 1);
}