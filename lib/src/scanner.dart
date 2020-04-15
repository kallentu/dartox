import 'dart:collection';

import "package:charcode/ascii.dart";
import 'package:dartox/src/error.dart';
import 'package:dartox/src/token.dart';
import 'package:dartox/src/token_type.dart';

class Scanner {
  final String _source;
  final List<Token> _tokens = List();

  final ErrorReporter _errorReporter = ErrorReporter();

  int _start = 0;
  int _current = 0;
  int _line = 0;

  final Map<String, TokenType> _keywords = HashMap<String, TokenType>();

  Scanner(this._source) {
    // Initialize the static keywords.
    _keywords.putIfAbsent("and", () => TokenType.AND);
    _keywords.putIfAbsent("class", () => TokenType.CLASS);
    _keywords.putIfAbsent("else", () => TokenType.ELSE);
    _keywords.putIfAbsent("false", () => TokenType.FALSE);
    _keywords.putIfAbsent("for", () => TokenType.FOR);
    _keywords.putIfAbsent("fun", () => TokenType.FUN);
    _keywords.putIfAbsent("if", () => TokenType.IF);
    _keywords.putIfAbsent("nil", () => TokenType.NIL);
    _keywords.putIfAbsent("or", () => TokenType.OR);
    _keywords.putIfAbsent("print", () => TokenType.PRINT);
    _keywords.putIfAbsent("return", () => TokenType.RETURN);
    _keywords.putIfAbsent("super", () => TokenType.SUPER);
    _keywords.putIfAbsent("this", () => TokenType.THIS);
    _keywords.putIfAbsent("true", () => TokenType.TRUE);
    _keywords.putIfAbsent("var", () => TokenType.VAR);
    _keywords.putIfAbsent("while", () => TokenType.WHILE);
  }

  List<Token> scanTokens() {
    while (!_isAtEnd()) {
      // We are at the beginning of the next lexeme.
      _start = _current;
      _scanToken();
    }

    _tokens.add(new Token(TokenType.EOF, "", null, _line));
    return _tokens;
  }

  void _scanToken() {
    int c = _advance();
    switch (c) {
      case $lparen:
        _addToken(TokenType.LEFT_PAREN);
        break;
      case $rparen:
        _addToken(TokenType.RIGHT_PAREN);
        break;
      case $lbrace:
        _addToken(TokenType.LEFT_BRACE);
        break;
      case $rbrace:
        _addToken(TokenType.RIGHT_BRACE);
        break;
      case $comma:
        _addToken(TokenType.COMMA);
        break;
      case $dot:
        _addToken(TokenType.DOT);
        break;
      case $minus:
        _addToken(TokenType.MINUS);
        break;
      case $plus:
        _addToken(TokenType.PLUS);
        break;
      case $semicolon:
        _addToken(TokenType.SEMICOLON);
        break;
      case $asterisk:
        _addToken(TokenType.STAR);
        break;
      case $question:
        _addToken(TokenType.QUESTION);
        break;
      case $colon:
        _addToken(TokenType.COLON);
        break;
      case $exclamation:
        _addToken(_match($equal) ? TokenType.BANG_EQUAL : TokenType.BANG);
        break;
      case $equal:
        _addToken(_match($equal) ? TokenType.EQUAL_EQUAL : TokenType.EQUAL);
        break;
      case $less_than:
        _addToken(_match($equal) ? TokenType.LESS_EQUAL : TokenType.LESS);
        break;
      case $greater_than:
        _addToken(_match($equal) ? TokenType.GREATER_EQUAL : TokenType.GREATER);
        break;
      case $slash:
        if (_match($slash)) {
          // // comments go until end of the line
          while (_peek() != $lf && !_isAtEnd()) _advance();
        } else if (_match($asterisk)) {
          // /* ... */ comments can continue multiple lines.
          // Move until comment ends.
          while (_peek() != $asterisk && _peekNext() != $slash && !_isAtEnd()) {
            if (_peek() == $lf) _line++;
            _advance();
          }

          // Unterminated comment
          if (_isAtEnd()) {
            return;
          }

          // Move past * and /
          _advance();
          _advance();
        } else {
          _addToken(TokenType.SLASH);
        }
        break;
      case $space:
      case $cr:
      case $tab:
        // Ignore whitespace
        break;
      case $lf:
        // Newline, increment counter.
        _line++;
        break;
      case $quotation:
        _string();
        break;
      default:
        if (_isDigit(c)) {
          _number();
        } else if (_isAlpha(c)) {
          _identifier();
        } else {
          // Keeps scanning after reporting error, but will not execute code.
          _errorReporter.error(_line, "Unexpected character.");
        }
        break;
    }
  }

  void _identifier() {
    while (_isAlphaNumeric(_peek())) _advance();

    // Check if identifier is a reserved word in [keywords]
    String text = _source.substring(_start, _current);
    if (_keywords.containsKey(text)) {
      TokenType type = _keywords[text];
      _addToken(type);
    } else {
      _addToken(TokenType.IDENTIFIER);
    }
  }

  void _number() {
    while (_isDigit(_peek())) _advance();

    // Look for a fractional part
    if (_peek() == $dot && _isDigit(_peekNext())) {
      // Consume the '.'
      _advance();

      while (_isDigit(_peek())) _advance();
    }

    _addToken(TokenType.NUMBER,
        literal: double.parse(_source.substring(_start, _current)));
  }

  /// Identify if the next token is equivalent to [expected].
  /// Only consumes the token if it is [expected].
  bool _match(int expected) {
    if (_isAtEnd()) return false;
    if (_source.codeUnitAt(_current) != expected) return false;
    _current++;
    return true;
  }

  /// Look at the next character without consuming.
  int _peek() {
    if (_isAtEnd()) return $nul;
    return _source.codeUnitAt(_current);
  }

  /// One look-ahead character for peeking.
  int _peekNext() {
    if (_current + 1 >= _source.length) return $nul;
    return _source.codeUnitAt(_current + 1);
  }

  bool _isAlpha(int c) =>
      (c >= $a && c <= $z) || (c >= $A && c <= $Z) || c == $_;

  bool _isAlphaNumeric(int c) => _isAlpha(c) || _isDigit(c);

  bool _isDigit(int c) => c >= $0 && c <= $9;

  bool _isAtEnd() => _current >= _source.length;

  int _advance() => _source.codeUnitAt(++_current - 1);

  void _addToken(TokenType type, {Object literal}) {
    String text = _source.substring(_start, _current);
    _tokens.add(new Token(type, text, literal, _line));
  }

  void _string() {
    // Move until string ends since it can be a multiline string.
    while (_peek() != $quotation && !_isAtEnd()) {
      if (_peek() == $lf) _line++;
      _advance();
    }

    // Unterminated string
    if (_isAtEnd()) {
      _errorReporter.error(_line, "Unterminated string.");
      return;
    }

    // Close quotation "
    _advance();

    // Trim the surrounding quotes
    String value = _source.substring(_start + 1, _current - 1);
    _addToken(TokenType.STRING, literal: value);
  }
}
