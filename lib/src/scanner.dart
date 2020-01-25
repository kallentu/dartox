import 'package:dartox/src/token.dart';
import 'package:dartox/src/token_type.dart';

class Scanner {
  final String _source;
  final List<Token> _tokens = List();

  int _start = 0;
  int _current = 0;
  int _line = 0;

  Scanner(this._source);

  List<Token> scanTokens() {
    while(!_isAtEnd()) {
      // We are at the beginning of the next lexeme.
      _start = _current;
      // TODO: scanToken();
    }

    _tokens.add(new Token(TokenType.EOF, "", null, _line));
    return _tokens;
  }

  bool _isAtEnd() => _current >= _source.length;
}
