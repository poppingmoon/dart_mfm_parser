import 'dart:math';

import 'package:mfm_parser/src/internal/utils.dart';
import 'package:mfm_parser/src/mfm_parser.dart';

class Success<T> implements Result<T> {
  const Success({required this.value, required this.index});

  final T value;
  final int index;
}

class Failure<T> implements Result<T> {
  const Failure();
}

sealed class Result<T> {}

class Span {
  const Span(this.start, this.end);

  final int start;
  final int end;
}

class ManyThenItems<T, U> {
  const ManyThenItems(this.items, this.afterValue);

  final List<T> items;
  final U afterValue;
}

typedef ParserHandler<T> =
    Result<T> Function(String input, int index, FullParserOpts state);

Success<T> success<T>(int index, T value) =>
    Success<T>(value: value, index: index);
Failure<T> failure<T>() => const Failure<Never>();

class Parser<T> {
  Parser({required this.handler, this.name, this.firstChars});

  String? name;
  late ParserHandler<T> handler;
  String? firstChars;

  Parser<U> map<U>(U Function(T value) fn) {
    return Parser<U>(
      handler: (input, index, state) {
        final result = handler(input, index, state);
        return switch (result) {
          Success(:final value, :final index) => success(index, fn(value)),
          Failure() => failure(),
        };
      },
    );
  }

  Parser<String> text() {
    return Parser(
      handler: (input, index, state) {
        final result = handler(input, index, state);
        return switch (result) {
          Success(index: final resultIndex) => success(
            resultIndex,
            input.substring(index, resultIndex),
          ),
          Failure() => failure(),
        };
      },
    );
  }

  Parser<List<T>> many(int min) {
    return Parser(
      handler: (input, index, state) {
        var latestIndex = index;
        final accum = <T>[];
        while (latestIndex < input.length) {
          final result = handler(input, latestIndex, state);
          if (result is! Success<T>) {
            break;
          }
          latestIndex = result.index;
          accum.add(result.value);
        }
        if (accum.length < min) {
          return failure();
        }
        return success(latestIndex, accum);
      },
    );
  }

  Parser<List<T>> sep(Parser<dynamic> separator, int min) {
    if (min < 1) {
      throw Exception('"min" must be a value greater than or equal to 1.');
    }

    return seq([
      this,
      seq([separator, this], select: 1).many(min - 1),
    ]).map(
      (result) => <T>[
        (result as List)[0] as T,
        for (final elem in result[1] as List) elem as T,
      ],
    );
  }

  Parser<T?> option() {
    return alt([this, succeeded(null)]);
  }
}

Parser<String> str(String value) {
  return Parser(
    handler: (input, index, _) {
      if (!input.startsWith(value, index)) {
        return failure();
      }

      return success(index + value.length, value);
    },
  );
}

Parser<String> regexp<T extends RegExp>(T pattern) {
  return Parser(
    handler: (input, index, _) {
      final result = pattern.matchAsPrefix(input, index);

      if (result == null) {
        return failure();
      }
      return success(index + result.group(0)!.length, result.group(0)!);
    },
  );
}

Parser<dynamic> seq(List<Parser<dynamic>> parsers, {int? select}) {
  return Parser(
    handler: (input, index, state) {
      var latestIndex = index;
      final accum = <dynamic>[];

      for (var i = 0; i < parsers.length; i++) {
        final result = parsers[i].handler(input, latestIndex, state);
        switch (result) {
          case Success(:final value, :final index):
            latestIndex = index;
            accum.add(value);
          case Failure():
            return failure();
        }
      }
      return success(latestIndex, (select != null ? accum[select] : accum));
    },
  );
}

Parser<T> alt<T>(List<Parser<T>> parsers) {
  final candidatesByChar = parsers.any((parser) => parser.firstChars != null)
      ? <int, List<Parser<T>>>{}
      : null;
  return Parser(
    handler: (input, index, state) {
      var candidates = parsers;
      if (candidatesByChar != null) {
        final code = index < input.length
            ? min(input.codeUnitAt(index), 0x80)
            : -1;
        candidates = candidatesByChar.putIfAbsent(
          code,
          () => parsers
              .where(
                (parser) => switch (parser.firstChars) {
                  final firstChars?
                      when code >= 0 &&
                          firstChars.contains(String.fromCharCode(code)) =>
                    true,
                  null => true,
                  _ => false,
                },
              )
              .toList(),
        );
      }
      for (final candidate in candidates) {
        final result = candidate.handler(input, index, state);
        if (result is Success) {
          return result;
        }
      }
      return failure();
    },
  );
}

Parser<T> first<T>(String chars, Parser<T> parser) {
  final guarded = Parser<T>(
    handler: (input, index, state) {
      if (index >= input.length || !chars.contains(input[index])) {
        return failure();
      }
      return parser.handler(input, index, state);
    },
  );
  guarded.firstChars = chars;
  return guarded;
}

Parser<T> succeeded<T>(T value) {
  return Parser(
    handler: (_, index, _) {
      return success(index, value);
    },
  );
}

Parser<void> notMatch(Parser<dynamic> parser) {
  return Parser(
    handler: (input, index, state) {
      final result = parser.handler(input, index, state);
      if (result is Failure) {
        return success(index, null);
      } else {
        return failure();
      }
    },
  );
}

int stateKey(FullParserOpts state) {
  return state.depth * 2 + (state.linkLabel ? 1 : 0);
}

Parser<String> until(Parser<dynamic> terminator, int min) {
  final parserKey = Object();
  return Parser(
    handler: (input, index, state) {
      state.untilSpans ??= {};
      final spans = state.untilSpans!.putIfAbsent(parserKey, () => {});
      final span = spans[input];
      int end;
      if (span != null && span.start <= index && index <= span.end) {
        end = span.end;
      } else {
        end = index;
        while (end < input.length &&
            terminator.handler(input, end, state) is Failure) {
          end++;
        }
        spans[input] = Span(index, end);
      }
      if (end - index < min) {
        return failure();
      }
      return success(end, input.substring(index, end));
    },
  );
}

Parser<ManyThenItems<T, U>> manyThen<T, U>(
  Parser<T> item,
  Parser<dynamic> stop,
  Parser<U> after,
  int min,
) {
  final element = seq([notMatch(stop), item], select: 1);
  final parserKey = Object();
  return Parser(
    handler: (input, index, state) {
      state.manyThenFailures ??= {};
      final byInput = state.manyThenFailures!.putIfAbsent(parserKey, () => {});
      final byState = byInput.putIfAbsent(input, () => {});
      final failures = byState.putIfAbsent(stateKey(state), () => {});
      final boundaries = <int>[];
      final items = <T>[];
      var latestIndex = index;
      while (!failures.contains(latestIndex)) {
        boundaries.add(latestIndex);
        if (latestIndex >= input.length) {
          break;
        }
        final result = element.handler(input, latestIndex, state);
        if (result is! Success) {
          break;
        }
        items.add(result.value as T);
        latestIndex = result.index;
      }
      if (items.length < min) {
        return failure();
      }
      final Result<U> afterResult = failures.contains(latestIndex)
          ? failure<U>()
          : after.handler(input, latestIndex, state);
      if (afterResult is! Success<U>) {
        failures.addAll(boundaries);
        return failure();
      }
      return success(
        afterResult.index,
        ManyThenItems(items, afterResult.value),
      );
    },
  );
}

final char = Parser<String>(
  handler: (input, index, _) {
    if ((input.length - index) < 1) {
      return failure();
    }
    final value = input[index];
    return success(index + 1, value);
  },
);

final lineBegin = Parser<void>(
  handler: (input, index, state) {
    if (index == 0) {
      return success(index, null);
    }
    if (isNewLine(input.codeUnitAt(index - 1))) {
      return success(index, null);
    }
    return failure();
  },
);

final lineEnd = Parser<void>(
  handler: (input, index, state) {
    if (index == input.length) {
      return success(index, null);
    }
    if (isNewLine(input.codeUnitAt(index))) {
      return success(index, null);
    }
    return failure();
  },
);

Parser<T> lazy<T>(Parser<T> Function() fn) {
  Parser<T>? parser;
  return parser = Parser(
    handler: (input, index, state) {
      parser!.handler = fn().handler;
      return parser.handler(input, index, state);
    },
  );
}

Parser<T> traced<T>(Parser<T> parser, String name) {
  return Parser(
    handler: (input, index, state) {
      final result = parser.handler(input, index, state);
      if (!state.trace) {
        return result;
      }
      final pos = "$index";
      // ignore: avoid_print
      print("${pos.padRight(6)}enter $name");
      switch (result) {
        case Success():
          final pos = "$index:${result.index}";
          // ignore: avoid_print
          print("${pos.padRight(6)}match $name");
        case Failure():
          final pos = "$index";
          // ignore: avoid_print
          print("${pos.padRight(6)}fail $name");
      }
      return result;
    },
    name: name,
  );
}

Map<String, Parser<dynamic>> createLanguage(
  Map<String, Parser<dynamic>? Function()> syntaxes,
) {
  final Map<String, Parser<dynamic>> rules = {};

  for (final entry in syntaxes.entries) {
    rules[entry.key] = lazy(() {
      final parser = syntaxes[entry.key]!();
      if (parser == null) {
        throw Exception('syntax must return a parser.');
      }
      return traced(parser, entry.key);
    });
  }
  return rules;
}
