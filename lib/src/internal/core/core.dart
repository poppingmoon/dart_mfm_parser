import 'package:mfm_parser/src/internal/extension/string_extension.dart';
import 'package:mfm_parser/src/mfm_parser.dart';

class Success<T> extends Result<T> {
  const Success({
    required super.value,
    required super.index,
    super.success = true,
  });
}

class Failure<T> extends Result<T> {
  const Failure({super.success = false});
}

abstract class Result<T> {
  final bool success;
  final T? value;
  final int? index;

  const Result({required this.success, this.value, this.index});
}

typedef ParserHandler<T> = Result<T> Function(
  String input,
  int index,
  FullParserOpts state,
);

Success<T> success<T>(int index, T value) =>
    Success<T>(value: value, index: index);
Failure<T> failure<T>() => Failure<T>();

class Parser<T> {
  String? name;
  late ParserHandler<T> handler;

  Parser({required ParserHandler<T> handler, this.name}) {
    this.handler = (input, index, state) {
      if (state.trace && name != null) {
        final pos = "$index";
        // ignore: avoid_print
        print("${pos.padRight(6)}enter $name");
        final result = handler(input, index, state);
        if (result.success) {
          final pos = "$index:${result.index}";
          // ignore: avoid_print
          print("${pos.padRight(6)}match $name");
        } else {
          final pos = "$index";
          // ignore: avoid_print
          print("${pos.padRight(6)}fail $name");
        }
        return result;
      }
      return handler(input, index, state);
    };
  }

  Parser<U> map<U>(U Function(T value) fn) {
    return Parser<U>(
      handler: (input, index, state) {
        final result = handler(input, index, state);
        if (!result.success) {
          if (result is! Failure<U>) {
            return failure<U>();
          }

          return result as Result<U>;
        }
        return success(result.index!, fn(result.value as T));
      },
    );
  }

  Parser<String> text() {
    return Parser(
      handler: (input, index, state) {
        final result = handler(input, index, state);
        if (!result.success) {
          if (result is! Result<String>) {
            return failure();
          }
          return result as Result<String>;
        }
        final succeed = result as Success;
        final text = input.substring(index, result.index);
        return success(succeed.index!, text);
      },
    );
  }

  Parser<List<T>> many(int min) {
    return Parser(
      handler: (input, index, state) {
        var latestIndex = index;
        final List<T> accum = [];
        while (latestIndex < input.length) {
          final result = handler(input, latestIndex, state);
          if (!result.success) {
            break;
          }
          latestIndex = result.index!;
          accum.add(result.value as T);
        }
        if (accum.length < min) {
          return failure<List<T>>();
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
      seq(
        [
          separator,
          this,
        ],
        select: 1,
      ).many(min - 1),
    ]).map(
      (result) => <T>[
        (result as List)[0] as T,
        for (final elem in result[1] as List) elem as T,
      ],
    );
  }

  Parser<T?> option() {
    return alt([
      this,
      succeeded(null),
    ]);
  }
}

Parser<String> str(String value) {
  return Parser(
    handler: (input, index, _) {
      if ((input.length - index) < value.length) {
        return failure();
      }
      if (input.substr(index, value.length) != value) {
        return failure();
      }

      return success(index + value.length, value);
    },
  );
}

Parser<String> regexp<T extends RegExp>(T pattern) {
  final re = RegExp('^(?:${pattern.pattern})');

  return Parser(
    handler: (input, index, _) {
      final text = input.substring(index);
      final result = re.firstMatch(text);

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
        if (!result.success) {
          return failure();
        }
        latestIndex = result.index!;
        accum.add(result.value);
      }
      return success(latestIndex, (select != null ? accum[select] : accum));
    },
  );
}

Parser<T> alt<T>(List<Parser<T>> parsers) {
  return Parser(
    handler: (input, index, state) {
      for (var i = 0; i < parsers.length; i++) {
        final result = parsers[i].handler(input, index, state);
        if (result.success) {
          return result;
        }
      }
      return failure();
    },
  );
}

Parser<T> succeeded<T>(T value) {
  return Parser(
    handler: (_, index, __) {
      return success(index, value);
    },
  );
}

Parser<void> notMatch(Parser<dynamic> parser) {
  return Parser(
    handler: (input, index, state) {
      final result = parser.handler(input, index, state);
      return !result.success ? success(index, null) : failure();
    },
  );
}

final cr = str("\r");
final lf = str("\n");
final crlf = str("\r\n");
final newline = alt([crlf, cr, lf]);
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
    if (cr.handler(input, index - 1, state).success) {
      return success(index, null);
    }
    if (lf.handler(input, index - 1, state).success) {
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
    if (cr.handler(input, index, state).success) {
      return success(index, null);
    }
    if (lf.handler(input, index, state).success) {
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

Map<String, Parser<dynamic>> createLanguage(
  Map<String, Parser<dynamic> Function()> syntaxes,
) {
  final Map<String, Parser<dynamic>> rules = {};

  for (final entry in syntaxes.entries) {
    rules[entry.key] = lazy(() {
      final parser = syntaxes[entry.key]!();
      parser.name = entry.key;
      return parser;
    });
  }
  return rules;
}
