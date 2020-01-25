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

  Scanner(this._source);

  List<Token> scanTokens() {
    while(!_isAtEnd()) {
      // We are at the beginning of the next lexeme.
      _start = _current;
      _scanToken();
    }

    _tokens.add(new Token(TokenType.EOF, "", null, _line));
    return _tokens;
  }

  void _scanToken() {
    int c = _advance();
    switch(c) {
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
      default:
        // Keeps scanning after reporting error, but will not execute code.
        _errorReporter.error(_line, "Unexpected character.");
        break;
    }
  }

  bool _isAtEnd() => _current >= _source.length;

  int _advance() => _source.codeUnitAt(++_current - 1);

  void _addToken(TokenType type, {Object literal}) {
    String text = _source.substring(_start, _current);
    _tokens.add(new Token(type, text, literal, _line));
  }
}
