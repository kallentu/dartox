import 'dart:io';
import 'package:args/args.dart';

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
  } else {
    // Run interactive prompt
    _runPrompt();
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