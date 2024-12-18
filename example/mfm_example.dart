import 'package:mfm_parser/mfm_parser.dart';

void main() {
  const input = r"""
<center>$[x2 **Hello, Markup language For Misskey.**]</center>

$[x2 1. Feature]

1. mention, such as @example @username@example.com
2. hashtag, such as #something
3. custom emoji, such as custom emoji :something_emoji: and 🚀🚀🚀

  """;
  final List<MfmNode> parsed = const MfmParser().parse(input);

  // ignore: avoid_print
  print(parsed);

  const userName = "🎂:ai_yay: momoi :ai_yay_fast:🎂@C100 Z-999";
  final List<MfmNode> parsedUserName = const MfmParser().parseSimple(userName);

  // ignore: avoid_print
  print(parsedUserName);
}
