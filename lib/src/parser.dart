import 'package:dartox/src/error.dart';
import 'package:dartox/src/expr.dart';
import 'package:dartox/src/statement.dart';
import 'package:dartox/src/token.dart';
import 'package:dartox/src/token_type.dart';

class Parser {
  final List<Token> _tokens;
  final ErrorReporter errorReporter;
  int _current = 0;

  Parser(this._tokens, this.errorReporter);

  List<Statement> parse() {
    List<Statement> statements = List();
    while (!_isAtEnd()) {
      statements.add(_declaration());
    }
    return statements;
  }

  /// declaration → classDecl
  ///            | funDecl
  ///            | varDecl
  ///            | statement
  Statement _declaration() {
    try {
      // Check if there is a declaration, otherwise move to (higher precedent)
      // statement.
      if (_match([TokenType.CLASS])) return _classDeclaration();
      if (_match([TokenType.FUN])) return _function("function");
      if (_match([TokenType.VAR])) return _varDeclaration();
      return _statement();
    } catch (e) {
      // Error recovery, try to parse the next valid statement/declaration.
      _synchronize();
      return null;
    }
  }

  /// classDecl → "class" IDENTIFIER "{" function* "}"
  Statement _classDeclaration() {
    Token name = _consume(TokenType.IDENTIFIER, "Expected class name.");
    _consume(TokenType.LEFT_BRACE, "Expected '{' before class body.");

    List<Function> methods = List();
    List<Function> staticMethods = List();
    List<Getter> getters = List();

    while (!_check(TokenType.RIGHT_BRACE) && !_isAtEnd()) {
      if (_match([TokenType.STATIC])) {
        staticMethods.add(_function("static method"));
      } else {
        // Either getter or a function
        Statement getOrFun = _function("method");
        if (getOrFun is Getter) {
          getters.add(getOrFun);
        } else if (getOrFun is Function) {
          methods.add(getOrFun);
        }
      }
    }

    _consume(TokenType.RIGHT_BRACE, "Expected '}' after class body.");
    return Class(name, methods, staticMethods, getters);
  }

  /// function → IDENTIFIER "(" parameters? ")" block | IDENTIFIER getter
  /// parameters → IDENTIFIER ( "," IDENTIFIER )*
  Statement _function(String kind) {
    Token name = _consume(TokenType.IDENTIFIER, "Expected " + kind + " name.");

    /// getter → block
    if (_match([TokenType.LEFT_BRACE])) {
      return Getter(name, _block());
    }

    // Parse the arguments.
    _consume(TokenType.LEFT_PAREN, "Expected '(' after " + kind + " name.");
    List<Token> parameters = List();
    if (!_check(TokenType.RIGHT_PAREN)) {
      do {
        // Parameter length for functions.
        if (parameters.length >= 255) {
          _error(_peek(), "Cannot have more than 255 parameters.");
        }

        parameters
            .add(_consume(TokenType.IDENTIFIER, "Expected parameter name."));
      } while (_match([TokenType.COMMA]));
    }
    _consume(TokenType.RIGHT_PAREN, "Expected ')' after parameters.");

    // Parse the block.
    _consume(TokenType.LEFT_BRACE, "Expected '{' before " + kind + " body.");
    List<Statement> body = _block();

    return Function(name, parameters, body);
  }

  /// varDecl → "var" IDENTIFIER ( "=" expression )? ";"
  Statement _varDeclaration() {
    Token name = _consume(TokenType.IDENTIFIER, "Expected variable name.");

    // Initial value for the variable.
    Expr initializer = null;
    if (_match([TokenType.EQUAL])) {
      initializer = _ternary();
    }

    _consume(TokenType.SEMICOLON, "Expected ';' after variable declaration.");
    return Var(name, initializer);
  }

  /// statement   → exprStmt
  ///            | forStmt
  ///            | ifStmt
  ///            | printStmt
  ///            | returnStmt
  ///            | whileStmt
  ///            | block
  ///            | breakStmt
  ///            | continueStmt
  Statement _statement() {
    if (_match([TokenType.FOR])) return _forStatement();
    if (_match([TokenType.IF])) return _ifStatement();
    if (_match([TokenType.PRINT])) return _printStatement();
    if (_match([TokenType.RETURN])) return _returnStatement();
    if (_match([TokenType.WHILE])) return _whileStatement();
    if (_match([TokenType.BREAK])) return _breakStatement();
    if (_match([TokenType.CONTINUE])) return _continueStatement();
    if (_match([TokenType.LEFT_BRACE])) return Block(_block());
    return _expressionStatement();
  }

  /// forStmt → "for" "(" ( varDecl | exprStmt | ";" )
  ///                    expression? ";"
  ///                    expression? ")" statement
  /// For loops are syntactic sugar for while loops.
  ///
  /// ie.
  /// for (var a = 0; a < 7; a = a + 1) { if (a == 2) { continue; } else { print a; } }
  /// for (var a = 0; a < 7; a = a + 1) { if (a == 2) { break; } else { print a; } }
  Statement _forStatement() {
    _consume(TokenType.LEFT_PAREN, "Expected '(' after 'for'.");

    // First clause being the initializer.
    // Either omitted, new variable or assignment.
    Statement initializer;
    if (_match([TokenType.SEMICOLON])) {
      initializer = null;
    } else if (_match([TokenType.VAR])) {
      initializer = _varDeclaration();
    } else {
      initializer = _expressionStatement();
    }

    Expr condition = null;
    if (!_check(TokenType.SEMICOLON)) {
      condition = _expression();
    }
    _consume(TokenType.SEMICOLON, "Expected ';' after loop condition.");

    Expr increment = null;
    if (!_check(TokenType.RIGHT_PAREN)) {
      increment = _expression();
    }
    _consume(TokenType.RIGHT_PAREN, "Expected ')' after for clauses.");

    Statement body = _statement();

    // If there is no condition, the for loop will always run.
    if (condition == null) condition = Literal(true);

    // Otherwise, use the condition given.
    // Also, add increment statement for break/continue usage.
    return For(initializer, condition, body, Expression(increment));
  }

  /// ifStmt → "if" "(" expression ")" statement ( "else" statement )?
  /// Nested else blocks are bound to nearest if that precedes it.
  Statement _ifStatement() {
    _consume(TokenType.LEFT_PAREN, "Expected '(' after 'if'.");
    Expr condition = _ternary();
    _consume(TokenType.RIGHT_PAREN, "Expected ')' after if condition.");

    Statement thenBranch = _statement();
    Statement elseBranch = null;
    if (_match([TokenType.ELSE])) {
      elseBranch = _statement();
    }

    return If(condition, thenBranch, elseBranch);
  }

  /// exprStmt → expression ";"
  Statement _expressionStatement() {
    Expr expr = _ternary();
    _consume(TokenType.SEMICOLON, "Expected ';' after expression.");
    return Expression(expr);
  }

  /// printStmt → "print" expression ";"
  Statement _printStatement() {
    Expr value = _ternary();
    _consume(TokenType.SEMICOLON, "Expected ';' after value.");
    return Print(value);
  }

  /// returnStmt → "return" expression? ";"
  Statement _returnStatement() {
    Token keyword = _previous();

    // Semicolon cannot be in an expression so check we don't reach it.
    Expr value = !_check(TokenType.SEMICOLON) ? _expression() : null;

    _consume(TokenType.SEMICOLON, "Expected ';' after return value.");
    return Return(keyword, value);
  }

  /// breakStmt → "break" ";"
  Statement _breakStatement() {
    Token breakToken = _previous();
    _consume(TokenType.SEMICOLON, "Expected ';' after break.");
    return Break(breakToken);
  }

  /// continueStmt → "continue" ";"
  Statement _continueStatement() {
    Token continueToken = _previous();
    _consume(TokenType.SEMICOLON, "Expected ';' after continue.");
    return Continue(continueToken);
  }

  /// whileStmt → "while" "(" expression ")" statement
  ///
  /// ie.
  /// var a = 0;
  /// while (a < 7) { a = a + 1; if (a == 2) { continue; } else { print a; } }
  Statement _whileStatement() {
    _consume(TokenType.LEFT_PAREN, "Expected '(' after 'while'.");
    Expr condition = _expression();
    _consume(TokenType.RIGHT_PAREN, "Expected ')' after condition.");

    Statement body = _statement();
    return While(condition, body);
  }

  /// block → "{" declaration* "}"
  List<Statement> _block() {
    List<Statement> statements = List();

    // Add each declaration until we hit the end of the block.
    while (!_check(TokenType.RIGHT_BRACE) && !_isAtEnd()) {
      statements.add(_declaration());
    }

    _consume(TokenType.RIGHT_BRACE, "Expected '}' after block.");
    return statements;
  }

  /// ternary → (commaExpression "?" commaExpression ":")* ternary
  ///        | commaExpression
  /// The ternary operator is left-associative.
  Expr _ternary() {
    Expr expr = _commaExpression();

    if (_match([TokenType.QUESTION])) {
      Token question = _previous();
      Expr left = _commaExpression();
      Token colon = _consume(TokenType.COLON, "Expected ':' after '?'.");
      Expr right = _ternary();
      expr = Ternary(expr, question, left, colon, right);
    }

    return expr;
  }

  /// commaExpression → expression ("," expression)*
  ///                | "," expression (as error production)
  Expr _commaExpression() {
    Expr expr;

    // Error production for missing left operand, consumes operator and expr.
    if (_match([TokenType.COMMA])) {
      Token operator = _previous();
      _expression(); // Consume the expression.
      _error(operator, "Expected left operand for comma expression.");
      expr = null;
    } else {
      // Have proper left operand.
      expr = _expression();
    }

    while (_match([TokenType.COMMA])) {
      Token comma = _previous();
      Expr right = _expression();
      expr = Binary(expr, comma, right);
    }

    return expr;
  }

  /// expression → assignment
  Expr _expression() => _assignment();

  /// assignment → ( call "." )? IDENTIFIER "=" assignment
  ///           | logic_or
  Expr _assignment() {
    // Parse left hand side. If it is actually assignment, this still works
    // since it is still an expression.
    Expr expr = _or();

    // If we find =, parse the right hand side.
    if (_match([TokenType.EQUAL])) {
      Token equals = _previous();
      Expr value = _assignment();

      // Confirm valid assignment target and convert to l-value representation.
      if (expr is Variable) {
        Token name = expr.name;
        return Assign(name, value);
      } else if (expr is Get) {
        return Set(expr.object, expr.name, value);
      } else {
        _error(equals, "Invalid assignment target.");
      }
    }

    return expr;
  }

  /// logic_or → logic_and ( "or" logic_and )*
  Expr _or() {
    Expr expr = _and();

    while (_match([TokenType.OR])) {
      Token operator = _previous();
      Expr right = _and();
      expr = Logical(expr, operator, right);
    }

    return expr;
  }

  /// logic_and → equality ( "and" equality )*
  Expr _and() {
    Expr expr = _equality();

    while (_match([TokenType.OR])) {
      Token operator = _previous();
      Expr right = _equality();
      expr = Logical(expr, operator, right);
    }

    return expr;
  }

  /// equality → comparison ( ( "!=" | "==" ) comparison )*
  ///         | ( "!=" | "==" ) comparison (as error production)
  Expr _equality() {
    Expr expr;

    // Error production for missing left operand, consumes operator and expr.
    if (_match([TokenType.BANG_EQUAL, TokenType.EQUAL_EQUAL])) {
      Token operator = _previous();
      _comparison(); // Consume the comparison.
      _error(operator, "Expected left operand for equality.");
      expr = null;
    } else {
      // Have proper left operand.
      expr = _comparison();
    }

    while (_match([TokenType.BANG_EQUAL, TokenType.EQUAL_EQUAL])) {
      Token operator = _previous();
      Expr right = _comparison();
      expr = Binary(expr, operator, right);
    }

    return expr;
  }

  /// comparison → addition ( ( ">" | ">=" | "<" | "<=" ) addition )*
  ///           | ( ">" | ">=" | "<" | "<=" ) addition (as error production)
  Expr _comparison() {
    Expr expr;

    // Error production for missing left operand, consumes operator and expr.
    if (_match([
      TokenType.GREATER,
      TokenType.GREATER_EQUAL,
      TokenType.LESS,
      TokenType.LESS_EQUAL
    ])) {
      Token operator = _previous();
      _addition(); // Consume the expression.
      _error(operator, "Expected left operand for comparison.");
      expr = null;
    } else {
      // Have proper left operand.
      expr = _addition();
    }

    while (_match([
      TokenType.GREATER,
      TokenType.GREATER_EQUAL,
      TokenType.LESS,
      TokenType.LESS_EQUAL
    ])) {
      Token operator = _previous();
      Expr right = _addition();
      expr = Binary(expr, operator, right);
    }

    return expr;
  }

  /// addition → multiplication ( ( "-" | "+" ) multiplication )*
  ///         | ( "-" | "+" ) multiplication (as error production)
  Expr _addition() {
    Expr expr;

    // Error production for missing left operand, consumes operator and expr.
    if (_match([TokenType.MINUS, TokenType.PLUS])) {
      Token operator = _previous();
      _multiplication(); // Consume the expression.
      _error(operator, "Expected left operand for addition/subtraction.");
      expr = null;
    } else {
      // Have proper left operand.
      expr = _multiplication();
    }

    while (_match([TokenType.MINUS, TokenType.PLUS])) {
      Token operator = _previous();
      Expr right = _multiplication();
      expr = Binary(expr, operator, right);
    }

    return expr;
  }

  /// multiplication → unary ( ( "/" | "*" ) unary )*
  ///               | ( "/" | "*" ) unary (as error production)
  Expr _multiplication() {
    Expr expr;

    // Error production for missing left operand, consumes operator and expr.
    if (_match([TokenType.SLASH, TokenType.STAR])) {
      Token operator = _previous();
      _unary(); // Consume the expression.
      _error(operator, "Expected left operand for multiplication/division.");
      expr = null;
    } else {
      // Have proper left operand.
      expr = _unary();
    }

    while (_match([TokenType.SLASH, TokenType.STAR])) {
      Token operator = _previous();
      Expr right = _unary();
      expr = Binary(expr, operator, right);
    }

    return expr;
  }

  /// unary → ( "!" | "-" ) unary
  ///      | call
  Expr _unary() {
    if (_match([TokenType.BANG, TokenType.MINUS])) {
      Token operator = _previous();
      Expr right = _unary();
      return Unary(operator, right);
    }

    return _call();
  }

  /// call → anonFun ( "(" arguments? ")" | "." IDENTIFIER )*
  Expr _call() {
    Expr expr = _anonFunction();

    while (true) {
      if (_match([TokenType.LEFT_PAREN])) {
        // Parse call expression using the previously parsed expression as
        // the callee.
        expr = _finishCall(expr);
      } else if (_match([TokenType.DOT])) {
        Token name =
            _consume(TokenType.IDENTIFIER, "Expected property name after '.'.");
        expr = Get(expr, name);
      } else {
        break;
      }
    }

    return expr;
  }

  /// arguments → expression ( "," expression )*
  /// Parses the argument list
  Expr _finishCall(Expr callee) {
    List<Expr> arguments = List();
    if (!_check(TokenType.RIGHT_PAREN)) {
      if (arguments.length >= 255) {
        _error(_peek(), "Cannot have more than 255 arguments.");
      }

      do {
        arguments.add(_expression());
      } while (_match([TokenType.COMMA]));
    }

    Token paren =
        _consume(TokenType.RIGHT_PAREN, "Expected ')' after arguments.");

    return Call(callee, paren, arguments);
  }

  /// anonFun → "fun" "(" parameters? ")" block
  ///         | primary
  /// parameters → IDENTIFIER ( "," IDENTIFIER )*
  Expr _anonFunction() {
    if (!_match([TokenType.FUN])) return _primary();

    // Parse the arguments.
    _consume(TokenType.LEFT_PAREN, "Expected '(' for anonymous function.");
    List<Token> parameters = List();
    if (!_check(TokenType.RIGHT_PAREN)) {
      do {
        // Parameter length for functions.
        if (parameters.length >= 255) {
          _error(_peek(), "Cannot have more than 255 parameters.");
        }

        parameters
            .add(_consume(TokenType.IDENTIFIER, "Expected parameter name."));
      } while (_match([TokenType.COMMA]));
    }
    _consume(TokenType.RIGHT_PAREN,
        "Expected ')' after anonymous function parameters.");

    // Parse the block.
    _consume(
        TokenType.LEFT_BRACE, "Expected '{' before anonymous function body.");
    List<Statement> body = _block();

    return AnonFunction(parameters, body);
  }

  /// primary → NUMBER | STRING | "false" | "true" | "nil" | "this"
  ///        | "(" expression ")"
  Expr _primary() {
    if (_match([TokenType.FALSE])) return Literal(false);
    if (_match([TokenType.TRUE])) return Literal(true);
    if (_match([TokenType.NIL])) return Literal(null);

    if (_match([TokenType.NUMBER, TokenType.STRING])) {
      return Literal(_previous().literal);
    }

    if (_match([TokenType.THIS])) return This(_previous());

    // Using a previously declared variable.
    if (_match([TokenType.IDENTIFIER])) {
      return Variable(_previous());
    }

    if (_match([TokenType.LEFT_PAREN])) {
      Expr expr = _expression();
      _consume(TokenType.RIGHT_PAREN, "Expected ')' after expression.");
      return Grouping(expr);
    }

    throw _error(_peek(), "Expected expression.");
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

  /// If correct type, will return token, otherwise throws error.
  Token _consume(TokenType type, String message) {
    if (_check(type)) return _advance();
    throw _error(_peek(), message);
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

  ParseError _error(Token token, String message) {
    errorReporter.tokenError(token, message);
    return ParseError();
  }

  /// Discards tokens until we move out of panic mode and into a new statement.
  void _synchronize() {
    _advance();

    while (!_isAtEnd()) {
      // Statement finished, return.
      if (_previous().type == TokenType.SEMICOLON) return;

      // Stop when we are about to start another statement.
      switch (_peek().type) {
        case TokenType.CLASS:
        case TokenType.FUN:
        case TokenType.VAR:
        case TokenType.FOR:
        case TokenType.IF:
        case TokenType.WHILE:
        case TokenType.PRINT:
        case TokenType.RETURN:
          return;
        default:
      }

      _advance();
    }
  }
}

class ParseError implements Exception {}
