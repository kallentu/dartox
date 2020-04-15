import 'dart:io';
import 'package:args/args.dart';
import 'package:dartox/src/token.dart';
import 'package:dartox/src/scanner.dart';
import 'package:dartox/src/error.dart';
import 'package:dartox/src/expr.dart';
import 'package:dartox/src/parser.dart';
import 'package:dartox/src/ast_printer.dart';

final ErrorReporter errorReporter = ErrorReporter();

main(List<String> args) {
  final ArgParser argParser = ArgParser()
    ..addOption('source', abbr: 's', help: "The file you want to compile.");
  ArgResults argResults = argParser.parse(args);

  if (argResults.arguments.length > 1) {
    // Too many arguments, help user with what they need to input.
    print("${argParser.usage}");
    exit(64);
  } else if (argResults.arguments.length == 1) {
    _run(argResults['file']);
    if (errorReporter.hadError) exit(65);
  } else {
    // Run interactive prompt
    _runPrompt();

    // If user makes error, we shouldn't close the entire session.
    errorReporter.clear();
  }
}

void _runPrompt() {
  for (;;) {
    stdout.write("> ");
    _run(stdin.readLineSync());
  }
}

void _run(String source) {
  Scanner scanner = Scanner(source);
  List<Token> tokens = scanner.scanTokens();
  Parser parser = Parser(tokens, errorReporter);
  Expr expression = parser.parse();

  _printTokens(tokens);

  // Stop if there is a syntax error.
  if (errorReporter.hadError) return;

  print(AstPrinter().print(expression));
}

/// Debug method to print all tokens.
void _printTokens(List<Token> tokens) {
  for (Token token in tokens) {
    print(token);
  }
}
