import 'dart:io';
import 'package:args/args.dart';

bool hadError = false;

main(List<String> args) {
  final ArgParser argParser = new ArgParser()
    ..addOption('source', abbr: 's', help: "The file you want to compile.");
  ArgResults argResults = argParser.parse(args);

  if (argResults.arguments.length > 1) {
    // Too many arguments, help user with what they need to input.
    print("${argParser.usage}");
    exit(64);
  } else if (argResults.arguments.length == 1) {
    _run(argResults['file']);
    if (hadError) exit(65);
  } else {
    // Run interactive prompt
    _runPrompt();

    // If user makes error, we shouldn't close the entire session.
    hadError = false;
  }
}

void _runPrompt() {
  for (;;) {
    stdout.write("> ");
    _run(stdin.readLineSync());
  }
}

void _run(String source) {
//    TODO(kallentu): Implement Scanner, Token.
//    Scanner scanner = new Scanner(source);
//    List<Token> tokens = scanner.scanTokens();
//
//    // For now, just print the tokens.
//    for (Token token : tokens) {
//      System.out.println(token);
//    }
}

void error(int line, String message) {
  _report(line, "", message);
}

void _report(int line, String where, String message) {
  print("[line $line] Error $where : $message");
  hadError = true;
}
