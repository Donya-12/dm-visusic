// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'dart:math' as math;

/// A readable syntax or evaluation error from the safe expression language.
final class ExpressionException implements Exception {
  /// Creates an expression error.
  const ExpressionException(this.message, {this.source, this.offset});

  /// Human-readable description of the problem.
  final String message;

  /// Expression source that caused the error, when available.
  final String? source;

  /// Zero-based source offset of the failing token, when available.
  final int? offset;

  @override
  String toString() {
    final location = offset == null ? '' : ' at column ${offset! + 1}';
    final expression = source == null ? '' : ' in "$source"';
    return 'ExpressionException: $message$location$expression';
  }
}

/// A parsed numeric expression that can be evaluated repeatedly.
///
/// The language supports numeric literals, paths, parentheses, unary plus and
/// minus, binary `+`, `-`, `*`, and `/`, and calls to `min`, `max`, `clamp`,
/// `lerp`, `mix`, `sin`, and `cos`. Values are read from the five path
/// namespaces supplied to [evaluate]. Missing `lyric.*` values default to zero;
/// missing values in other namespaces are errors.
final class NumericExpression {
  NumericExpression._(this.source, this._root);

  /// Parses [source] without executing any external code.
  factory NumericExpression.parse(String source) {
    final tokens = _Tokenizer(source).tokenize();
    final parser = _Parser(source, tokens);
    final root = parser.parseExpression();
    final end = parser.current;
    if (end.type != _TokenType.end) {
      throw ExpressionException(
        'Unexpected token "${end.text}"; expected an operator or end of input',
        source: source,
        offset: end.offset,
      );
    }
    return NumericExpression._(source, root);
  }

  /// Original expression source.
  final String source;

  final _Expression _root;

  /// Evaluates the expression with numeric values for each path namespace.
  ///
  /// Map keys do not include their namespace. For example, `params.pulse`
  /// resolves `params['pulse']`, and `audio.level.rms` resolves
  /// `audio['level.rms']`. Angles passed to [math.sin] and [math.cos] are in
  /// radians. `mix` is an alias for the three-argument linear interpolation
  /// function `lerp`.
  double evaluate({
    Map<String, double> params = const <String, double>{},
    Map<String, double> bind = const <String, double>{},
    Map<String, double> time = const <String, double>{},
    Map<String, double> audio = const <String, double>{},
    Map<String, double> lyric = const <String, double>{},
  }) {
    final context = _EvaluationContext(
      source: source,
      params: params,
      bind: bind,
      time: time,
      audio: audio,
      lyric: lyric,
    );
    return _root.evaluate(context);
  }
}

/// Parses and evaluates [source] in one call.
///
/// This is a convenience wrapper around [NumericExpression.parse] followed by
/// [NumericExpression.evaluate]. Reuse a [NumericExpression] when evaluating
/// the same source for many frames.
double evaluateExpression(
  String source, {
  Map<String, double> params = const <String, double>{},
  Map<String, double> bind = const <String, double>{},
  Map<String, double> time = const <String, double>{},
  Map<String, double> audio = const <String, double>{},
  Map<String, double> lyric = const <String, double>{},
}) {
  return NumericExpression.parse(source).evaluate(
    params: params,
    bind: bind,
    time: time,
    audio: audio,
    lyric: lyric,
  );
}

final class _EvaluationContext {
  const _EvaluationContext({
    required this.source,
    required this.params,
    required this.bind,
    required this.time,
    required this.audio,
    required this.lyric,
  });

  final String source;
  final Map<String, double> params;
  final Map<String, double> bind;
  final Map<String, double> time;
  final Map<String, double> audio;
  final Map<String, double> lyric;

  double valueAt(_Token token) {
    final path = token.text;
    final separator = path.indexOf('.');
    if (separator <= 0 || separator == path.length - 1) {
      throw ExpressionException(
        'Unknown path "$path"; expected params.*, bind.*, time.*, audio.*, or lyric.*',
        source: source,
        offset: token.offset,
      );
    }
    final namespace = path.substring(0, separator);
    final name = path.substring(separator + 1);
    if (namespace == 'lyric') {
      return _finite(lyric[name] ?? 0, 'Path "$path"', token);
    }
    final values = switch (namespace) {
      'params' => params,
      'bind' => bind,
      'time' => time,
      'audio' => audio,
      _ => null,
    };
    if (values == null || !values.containsKey(name)) {
      throw ExpressionException(
        'Unknown path "$path"',
        source: source,
        offset: token.offset,
      );
    }
    return _finite(values[name]!, 'Path "$path"', token);
  }

  double _finite(double value, String subject, _Token token) {
    if (!value.isFinite) {
      throw ExpressionException(
        '$subject produced a non-finite value',
        source: source,
        offset: token.offset,
      );
    }
    return value;
  }
}

sealed class _Expression {
  const _Expression();

  double evaluate(_EvaluationContext context);
}

final class _LiteralExpression extends _Expression {
  const _LiteralExpression(this.value);

  final double value;

  @override
  double evaluate(_EvaluationContext context) => value;
}

final class _PathExpression extends _Expression {
  const _PathExpression(this.token);

  final _Token token;

  @override
  double evaluate(_EvaluationContext context) => context.valueAt(token);
}

final class _UnaryExpression extends _Expression {
  const _UnaryExpression(this.operator, this.operand);

  final _Token operator;
  final _Expression operand;

  @override
  double evaluate(_EvaluationContext context) {
    final value = operand.evaluate(context);
    return operator.type == _TokenType.minus ? -value : value;
  }
}

final class _BinaryExpression extends _Expression {
  const _BinaryExpression(this.left, this.operator, this.right);

  final _Expression left;
  final _Token operator;
  final _Expression right;

  @override
  double evaluate(_EvaluationContext context) {
    final leftValue = left.evaluate(context);
    final rightValue = right.evaluate(context);
    if (operator.type == _TokenType.slash && rightValue == 0) {
      throw ExpressionException(
        'Division by zero',
        source: context.source,
        offset: operator.offset,
      );
    }
    final value = switch (operator.type) {
      _TokenType.plus => leftValue + rightValue,
      _TokenType.minus => leftValue - rightValue,
      _TokenType.star => leftValue * rightValue,
      _TokenType.slash => leftValue / rightValue,
      _ => throw StateError('Unexpected binary operator ${operator.type}.'),
    };
    if (!value.isFinite) {
      throw ExpressionException(
        'Arithmetic produced a non-finite result',
        source: context.source,
        offset: operator.offset,
      );
    }
    return value;
  }
}

final class _FunctionExpression extends _Expression {
  const _FunctionExpression(this.name, this.arguments);

  final _Token name;
  final List<_Expression> arguments;

  static const Map<String, int> _arities = <String, int>{
    'min': 2,
    'max': 2,
    'clamp': 3,
    'lerp': 3,
    'mix': 3,
    'sin': 1,
    'cos': 1,
  };

  @override
  double evaluate(_EvaluationContext context) {
    final expectedArity = _arities[name.text];
    if (expectedArity == null) {
      throw ExpressionException(
        'Unknown function "${name.text}"',
        source: context.source,
        offset: name.offset,
      );
    }
    if (arguments.length != expectedArity) {
      throw ExpressionException(
        'Function "${name.text}" expects $expectedArity argument(s), got ${arguments.length}',
        source: context.source,
        offset: name.offset,
      );
    }
    final values = arguments
        .map((argument) => argument.evaluate(context))
        .toList(growable: false);
    if (name.text == 'clamp' && values[1] > values[2]) {
      throw ExpressionException(
        'Function "clamp" requires minimum <= maximum',
        source: context.source,
        offset: name.offset,
      );
    }
    final value = switch (name.text) {
      'min' => math.min(values[0], values[1]),
      'max' => math.max(values[0], values[1]),
      'clamp' => math.min(math.max(values[0], values[1]), values[2]),
      'lerp' || 'mix' => values[0] + (values[1] - values[0]) * values[2],
      'sin' => math.sin(values[0]),
      'cos' => math.cos(values[0]),
      _ => throw StateError('Unexpected function ${name.text}.'),
    };
    if (!value.isFinite) {
      throw ExpressionException(
        'Function "${name.text}" produced a non-finite result',
        source: context.source,
        offset: name.offset,
      );
    }
    return value;
  }
}

final class _Parser {
  _Parser(this.source, this.tokens);

  final String source;
  final List<_Token> tokens;
  int _index = 0;

  _Token get current => tokens[_index];

  _Expression parseExpression() => _parseSum();

  _Expression _parseSum() {
    var expression = _parseProduct();
    while (current.type == _TokenType.plus ||
        current.type == _TokenType.minus) {
      final operator = _advance();
      expression = _BinaryExpression(expression, operator, _parseProduct());
    }
    return expression;
  }

  _Expression _parseProduct() {
    var expression = _parseUnary();
    while (current.type == _TokenType.star ||
        current.type == _TokenType.slash) {
      final operator = _advance();
      expression = _BinaryExpression(expression, operator, _parseUnary());
    }
    return expression;
  }

  _Expression _parseUnary() {
    if (current.type == _TokenType.plus || current.type == _TokenType.minus) {
      final operator = _advance();
      return _UnaryExpression(operator, _parseUnary());
    }
    return _parsePrimary();
  }

  _Expression _parsePrimary() {
    final token = current;
    switch (token.type) {
      case _TokenType.number:
        _advance();
        return _LiteralExpression(token.number!);
      case _TokenType.identifier:
        _advance();
        if (current.type != _TokenType.leftParen) {
          return _PathExpression(token);
        }
        _advance();
        final arguments = <_Expression>[];
        if (current.type != _TokenType.rightParen) {
          while (true) {
            arguments.add(parseExpression());
            if (current.type != _TokenType.comma) {
              break;
            }
            _advance();
          }
        }
        _expect(_TokenType.rightParen, 'Expected ")" after function arguments');
        return _FunctionExpression(token, List.unmodifiable(arguments));
      case _TokenType.leftParen:
        _advance();
        final expression = parseExpression();
        _expect(_TokenType.rightParen, 'Expected ")" to close the group');
        return expression;
      case _TokenType.end:
        throw ExpressionException(
          'Expected a number, path, function, or parenthesized expression',
          source: source,
          offset: token.offset,
        );
      default:
        throw ExpressionException(
          'Unexpected token "${token.text}"; expected a value',
          source: source,
          offset: token.offset,
        );
    }
  }

  void _expect(_TokenType type, String message) {
    if (current.type != type) {
      throw ExpressionException(
        message,
        source: source,
        offset: current.offset,
      );
    }
    _advance();
  }

  _Token _advance() {
    final token = current;
    if (token.type != _TokenType.end) {
      _index++;
    }
    return token;
  }
}

final class _Tokenizer {
  _Tokenizer(this.source);

  final String source;
  int _offset = 0;

  List<_Token> tokenize() {
    final tokens = <_Token>[];
    while (_offset < source.length) {
      final character = source[_offset];
      if (character == ' ' ||
          character == '\t' ||
          character == '\r' ||
          character == '\n') {
        _offset++;
        continue;
      }
      final start = _offset;
      if (_isDigit(character) ||
          (character == '.' &&
              _offset + 1 < source.length &&
              _isDigit(source[_offset + 1]))) {
        tokens.add(_number(start));
        continue;
      }
      if (_isIdentifierStart(character)) {
        tokens.add(_identifier(start));
        continue;
      }
      final type = switch (character) {
        '+' => _TokenType.plus,
        '-' => _TokenType.minus,
        '*' => _TokenType.star,
        '/' => _TokenType.slash,
        '(' => _TokenType.leftParen,
        ')' => _TokenType.rightParen,
        ',' => _TokenType.comma,
        _ => null,
      };
      if (type == null) {
        throw ExpressionException(
          'Unexpected character "$character"',
          source: source,
          offset: start,
        );
      }
      _offset++;
      tokens.add(_Token(type, character, start));
    }
    tokens.add(_Token(_TokenType.end, '', source.length));
    return List.unmodifiable(tokens);
  }

  _Token _number(int start) {
    while (_offset < source.length && _isDigit(source[_offset])) {
      _offset++;
    }
    if (_offset < source.length && source[_offset] == '.') {
      _offset++;
      while (_offset < source.length && _isDigit(source[_offset])) {
        _offset++;
      }
    }
    if (_offset < source.length &&
        (source[_offset] == 'e' || source[_offset] == 'E')) {
      _offset++;
      if (_offset < source.length &&
          (source[_offset] == '+' || source[_offset] == '-')) {
        _offset++;
      }
      final exponentStart = _offset;
      while (_offset < source.length && _isDigit(source[_offset])) {
        _offset++;
      }
      if (exponentStart == _offset) {
        throw ExpressionException(
          'Expected digits in the numeric exponent',
          source: source,
          offset: _offset,
        );
      }
    }
    final text = source.substring(start, _offset);
    final value = double.tryParse(text);
    if (value == null || !value.isFinite) {
      throw ExpressionException(
        'Invalid or non-finite numeric literal "$text"',
        source: source,
        offset: start,
      );
    }
    return _Token(_TokenType.number, text, start, value);
  }

  _Token _identifier(int start) {
    _offset++;
    while (_offset < source.length && _isIdentifierPart(source[_offset])) {
      _offset++;
    }
    while (_offset + 1 < source.length &&
        source[_offset] == '.' &&
        _isIdentifierStart(source[_offset + 1])) {
      _offset += 2;
      while (_offset < source.length && _isIdentifierPart(source[_offset])) {
        _offset++;
      }
    }
    return _Token(
      _TokenType.identifier,
      source.substring(start, _offset),
      start,
    );
  }

  bool _isDigit(String character) {
    final code = character.codeUnitAt(0);
    return code >= 0x30 && code <= 0x39;
  }

  bool _isIdentifierStart(String character) {
    final code = character.codeUnitAt(0);
    return character == '_' ||
        (code >= 0x41 && code <= 0x5a) ||
        (code >= 0x61 && code <= 0x7a);
  }

  bool _isIdentifierPart(String character) =>
      _isIdentifierStart(character) || _isDigit(character);
}

enum _TokenType {
  number,
  identifier,
  plus,
  minus,
  star,
  slash,
  leftParen,
  rightParen,
  comma,
  end,
}

final class _Token {
  const _Token(this.type, this.text, this.offset, [this.number]);

  final _TokenType type;
  final String text;
  final int offset;
  final double? number;
}
