import 'package:mfm_parser/src/internal/core/core.dart';
import 'package:mfm_parser/src/internal/language.dart';
import 'package:mfm_parser/src/internal/utils.dart';
import 'package:mfm_parser/src/node.dart';

/// parse full syntax.
/// if you want to limit elements nest, input [nestLimit]
List<MfmNode> parse(String input, {int? nestLimit}) {
  final result = language.fullParser.handler(
    input,
    0,
    FullParserOpts(
      nestLimit: nestLimit ?? 20,
      depth: 0,
      linkLabel: false,
      trace: false,
    ),
  ) as Success<List<dynamic>>;

  return mergeText(result.value);
}

/// parse limited syntax.
/// it will parse text or emoji.
List<MfmNode> parseSimple(String input) {
  final result = language.simpleParser.handler(
    input,
    0,
    FullParserOpts(
      nestLimit: 20,
      depth: 0,
      linkLabel: false,
      trace: false,
    ),
  ) as Success<List<dynamic>>;

  return mergeText(result.value);
}

class FullParserOpts {
  int nestLimit;
  int depth;
  bool linkLabel;
  bool trace;

  FullParserOpts({
    required this.nestLimit,
    required this.depth,
    required this.linkLabel,
    required this.trace,
  });
}
