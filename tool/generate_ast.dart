import 'dart:io';
import 'package:args/args.dart';
import 'package:charcode/ascii.dart';

/// generate_ast.dart generates boiler-plate AST files.
/// Eg. "dart tool/generate_ast.dart lib/src"
main(List<String> args) {
  final ArgParser argParser = new ArgParser();
  ArgResults argResults = argParser.parse(args);

  // Only one argument for this script.
  if (argResults.arguments.length != 1) {
    print("Usage: generate_ast <output directory>");
    exit(1);
  }

  String outputDir = argResults.arguments.elementAt(0);
  _defineAst(outputDir, "Expr", [
    "package:dartox/src/token.dart"
  ], [
    "Binary   : Expr left, Token operator, Expr right",
    "Grouping : Expr expression",
    "Literal  : Object value",
    "Unary    : Token operator, Expr right"
  ]);
}

void _defineAst(String outputDir, String baseName, List<String> imports,
    List<String> types) {
  // Pre-process if there's an extra / character.
  if (outputDir.codeUnitAt(outputDir.length - 1) == $slash) {
    outputDir = outputDir.substring(0, outputDir.length - 1);
  }

  String path = outputDir + "/" + baseName.toLowerCase() + ".dart";
  String contents = "";

  // Imports
  for (String import in imports) {
    contents += "import '" + import + "';\n";
  }

  contents += "\n";
  contents += "abstract class " + baseName + " {\n";

  // Base accept() method.
  contents += "  R accept<R>(" + baseName + "Visitor<R> visitor);\n";

  contents += "}\n\n";

  // Add the visitor for the AST classes
  contents += _defineVisitor(baseName, types) + "\n";

  // Add the AST classes to the file.
  for (int i = 0; i < types.length; i++) {
    String className = types[i].split(":")[0].trim();
    String fields = types[i].split(":")[1].trim();
    contents += _defineType(baseName, className, fields);

    // Add newline if not last type.
    if (i != types.length - 1) {
      contents += "\n";
    }
  }

  // Create new file for this AST.
  new File(path).writeAsString(contents);
}

String _defineVisitor(String baseName, List<String> types) {
  String contents = "abstract class " + baseName + "Visitor<R> {\n";

  for (String type in types) {
    String typeName = type.split(":")[0].trim();
    contents += "  R visit" +
        typeName +
        baseName +
        "(" +
        typeName +
        " " +
        baseName.toLowerCase() +
        ");\n";
  }

  contents += "}\n";

  return contents;
}

String _defineType(String baseName, String className, String fieldList) {
  String contents = "class " + className + " extends " + baseName + " {\n";

  // Fields
  List<String> fields = fieldList.split(", ");
  for (String field in fields) {
    contents += "  final " + field + ";\n";
  }

  // Constructor
  contents += "  " + className + "(";
  for (int i = 0; i < fields.length; i++) {
    String name = fields[i].split(" ")[1];
    contents += "this." + name;

    // Add comma if not last field.
    if (i != fields.length - 1) {
      contents += ", ";
    }
  }
  contents += ");\n";

  // Visitor pattern
  contents += "  @override\n";
  contents += "  R accept<R>(" + baseName + "Visitor<R> visitor) {\n";
  contents += "    return visitor.visit" + className + baseName + "(this);\n";
  contents += "  }\n";

  contents += "}\n";
  return contents;
}
