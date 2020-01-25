// TODO: Add error type class.
class ErrorReporter {
  bool hadError = false;

  void error(int line, String message) {
    _report(line, "", message);
  }

  void clear() => hadError = false;

  void _report(int line, String where, String message) {
    print("[line $line] Error $where : $message");
    hadError = true;
  }
}
