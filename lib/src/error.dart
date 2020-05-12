import 'package:dartox/src/runtime_error.dart';
import 'package:dartox/src/token.dart';
import 'package:dartox/src/token_type.dart';

class ErrorReporter {
  bool hadError = false;
  bool hadRuntimeError = false;

  void simpleError(String message) {
    _reportSimple(message);
  }

  void lineError(int line, String message) {
    _report(line, "", message);
  }

  /// Report token location and token itself.
  void tokenError(Token token, String message) {
    if (token.type == TokenType.EOF) {
      _report(token.line, "at end", message);
    } else {
      _report(token.line, "at '" + token.lexeme + "'", message);
    }
  }

  void runtimeError(RuntimeError error) {
    print(error.toString() + "\n[line " + error.token.line.toString() + "]");
    hadRuntimeError = true;
  }

  void clear() => hadError = false;

  void _report(int line, String where, String message) {
    print("[line $line] Error $where : $message");
    hadError = true;
  }

  void _reportSimple(String message) {
    print("Error : $message");
    hadError = true;
  }
}
