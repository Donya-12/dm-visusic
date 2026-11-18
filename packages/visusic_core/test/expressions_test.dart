// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'dart:math' as math;

import 'package:test/test.dart';
import 'package:visusic_core/src/expressions.dart';

void main() {
  group('NumericExpression parsing and arithmetic', () {
    test('uses standard precedence, associativity, and grouping', () {
      expect(evaluateExpression('1 + 2 * 3'), 7);
      expect(evaluateExpression('(1 + 2) * 3'), 9);
      expect(evaluateExpression('20 / 5 / 2'), 2);
      expect(evaluateExpression('10 - 3 - 2'), 5);
      expect(evaluateExpression('2 * -3 + +4'), -2);
      expect(evaluateExpression('-(-2 - 3)'), 5);
    });

    test('accepts decimal and exponent literals and whitespace', () {
      expect(evaluateExpression(' .5 + 1. + 1.5e2 - 5E-1 '), 151);
      expect(evaluateExpression('\n2\t*\r(3 + 1)'), 8);
    });

    test('can parse once and evaluate with independent contexts', () {
      final expression = NumericExpression.parse(
        '(params.pulse + bind.kick) * 2',
      );
      expect(
        expression.evaluate(
          params: <String, double>{'pulse': 2},
          bind: <String, double>{'kick': 1},
        ),
        6,
      );
      expect(
        expression.evaluate(
          params: <String, double>{'pulse': 5},
          bind: <String, double>{'kick': 0.5},
        ),
        11,
      );
      expect(expression.source, '(params.pulse + bind.kick) * 2');
    });
  });

  group('safe functions', () {
    test('supports the complete allowlist and nesting', () {
      expect(evaluateExpression('min(4, -2)'), -2);
      expect(evaluateExpression('max(4, -2)'), 4);
      expect(evaluateExpression('clamp(12, -2, 5)'), 5);
      expect(evaluateExpression('clamp(-12, -2, 5)'), -2);
      expect(evaluateExpression('clamp(2, -2, 5)'), 2);
      expect(evaluateExpression('lerp(-2, 6, 0.25)'), 0);
      expect(evaluateExpression('mix(-2, 6, 0.75)'), 4);
      expect(evaluateExpression('sin(0) + cos(0)'), 1);
      expect(evaluateExpression('sin(${math.pi / 2})'), closeTo(1, 1e-12));
      expect(evaluateExpression('max(min(8, 3), clamp(10, 0, 6)) + 1'), 7);
    });

    test('does not silently accept unknown functions or wrong arities', () {
      for (final source in <String>[
        'pow(2, 3)',
        'min(1)',
        'max(1, 2, 3)',
        'clamp(1, 2)',
        'lerp(1, 2)',
        'mix(1, 2, 3, 4)',
        'sin(1, 2)',
        'cos()',
      ]) {
        expect(
          () => evaluateExpression(source),
          throwsA(
            isA<ExpressionException>().having(
              (error) => error.toString().toLowerCase(),
              'readable error',
              contains('function'),
            ),
          ),
          reason: source,
        );
      }
      expect(
        () => evaluateExpression('pow(2, 3)'),
        throwsA(
          isA<ExpressionException>().having(
            (error) => error.message,
            'message',
            contains('Unknown function "pow"'),
          ),
        ),
      );
    });

    test('rejects reversed clamp limits', () {
      expect(
        () => evaluateExpression('clamp(1, 3, 2)'),
        throwsA(
          isA<ExpressionException>()
              .having(
                (error) => error.message,
                'message',
                contains('minimum <= maximum'),
              )
              .having((error) => error.source, 'source', 'clamp(1, 3, 2)'),
        ),
      );
    });
  });

  group('expression paths', () {
    test('reads all namespaces including dotted aliases', () {
      final result = evaluateExpression(
        'params.pulse + bind.kick + time.now + time.progress + '
        'audio.energy + audio.level.rms + lyric.lineProgress',
        params: <String, double>{'pulse': 0.25},
        bind: <String, double>{'kick': 1},
        time: <String, double>{'now': 2, 'progress': 0.2},
        audio: <String, double>{'energy': 0.5, 'level.rms': 0.1},
        lyric: <String, double>{'lineProgress': 0.4},
      );
      expect(result, closeTo(4.45, 1e-12));
    });

    test('uses zero for absent lyric paths', () {
      expect(
        evaluateExpression(
          'lyric.wordProgress + lyric.anyFutureValue + 2',
          lyric: <String, double>{'wordProgress': 0.3},
        ),
        closeTo(2.3, 1e-12),
      );
    });

    test('rejects unknown and non-numeric paths with source context', () {
      for (final source in <String>[
        'params.missing',
        'bind.missing',
        'time.missing',
        'audio.missing',
        'unknown.value',
        'standalone',
      ]) {
        expect(
          () => evaluateExpression(source),
          throwsA(
            isA<ExpressionException>()
                .having((error) => error.source, 'source', source)
                .having((error) => error.message, 'message', contains('path')),
          ),
          reason: source,
        );
      }
      expect(
        () => evaluateExpression(
          'params.bad',
          params: <String, double>{'bad': double.infinity},
        ),
        throwsA(
          isA<ExpressionException>().having(
            (error) => error.message,
            'message',
            contains('non-finite'),
          ),
        ),
      );
    });
  });

  group('readable failures', () {
    test('rejects malformed syntax and unexpected characters', () {
      for (final source in <String>[
        '',
        '   ',
        '1 +',
        '(1 + 2',
        '1 2',
        '1..2',
        '1, 2',
        'min(1,)',
        'min(,1)',
        '1 @ 2',
        '1e+',
      ]) {
        expect(
          () => evaluateExpression(source),
          throwsA(isA<ExpressionException>()),
          reason: source,
        );
      }
    });

    test('reports division by zero at the operator', () {
      expect(
        () => evaluateExpression('8 / (3 - 3)'),
        throwsA(
          isA<ExpressionException>()
              .having((error) => error.message, 'message', 'Division by zero')
              .having((error) => error.offset, 'offset', 2)
              .having(
                (error) => error.toString(),
                'formatted error',
                contains('at column 3 in "8 / (3 - 3)"'),
              ),
        ),
      );
    });

    test('rejects non-finite literals and arithmetic results', () {
      expect(
        () => evaluateExpression('1e999'),
        throwsA(_throwsExpressionError),
      );
      expect(
        () => evaluateExpression('1e308 * 1e308'),
        throwsA(_throwsExpressionError),
      );
      expect(
        () => evaluateExpression('-1e308 * 1e308'),
        throwsA(_throwsExpressionError),
      );
    });
  });
}

final _throwsExpressionError = isA<ExpressionException>();
