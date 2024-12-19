import 'package:mfm_parser/src/internal/core/core.dart';
import 'package:mfm_parser/src/internal/extension/string_extension.dart';
import 'package:mfm_parser/src/internal/tweemoji_parser.dart';
import 'package:mfm_parser/src/internal/utils.dart';
import 'package:mfm_parser/src/node.dart';

final space = regexp(RegExp(r"[\u0020\u3000\t]"));
final alphaAndNum = regexp(RegExp("[a-zA-Z0-9]"));
final newLine = alt([crlf, cr, lf]);

Parser<dynamic> seqOrText(List<Parser<dynamic>> parsers) {
  return Parser(
    handler: (input, index, state) {
      final accum = <dynamic>[];
      var latestIndex = index;
      for (var i = 0; i < parsers.length; i++) {
        final result = parsers[i].handler(input, latestIndex, state);
        switch (result) {
          case Success(:final value, :final index):
            accum.add(value);
            latestIndex = index;
          case Failure():
            if (latestIndex == index) {
              return failure();
            } else {
              return success(latestIndex, input.slice(index, latestIndex));
            }
        }
      }
      return success(latestIndex, accum);
    },
  );
}

Parser<void> notLinkLabel = Parser(
  handler: (_, index, state) {
    return (!state.linkLabel) ? success(index, null) : failure();
  },
);

Parser<void> nestable = Parser(
  handler: (_, index, state) {
    return (state.depth < state.nestLimit) ? success(index, null) : failure();
  },
);

Parser<dynamic> nest(Parser<dynamic> parser, {Parser<dynamic>? fallback}) {
  final inner = alt([
    seq([nestable, parser], select: 1),
    if (fallback != null) fallback else char,
  ]);
  return Parser(
    handler: (input, index, state) {
      state.depth++;
      final result = inner.handler(input, index, state);
      state.depth--;
      return result;
    },
  );
}

class Language {
  late final Map<String, Parser<dynamic>> _l;
  Parser<List<dynamic>> get fullParser => _l["full"]!.many(0);
  Parser<List<dynamic>> get simpleParser => _l["simple"]!.many(0);
  Parser<dynamic> get quote => _l["quote"]!;
  Parser<dynamic> get big => _l["big"]!;
  Parser<dynamic> get boldAsta => _l["boldAsta"]!;
  Parser<dynamic> get boldTag => _l["boldTag"]!;
  Parser<dynamic> get text => _l["text"]!;
  Parser<dynamic> get inline => _l["inline"]!;
  Parser<dynamic> get boldUnder => _l["boldUnder"]!;
  Parser<dynamic> get smallTag => _l["smallTag"]!;
  Parser<dynamic> get italicTag => _l["italicTag"]!;
  Parser<dynamic> get italicAsta => _l["italicAsta"]!;
  Parser<dynamic> get italicUnder => _l["italicUnder"]!;
  Parser<dynamic> get codeBlock => _l["codeBlock"]!;
  Parser<dynamic> get strikeTag => _l["strikeTag"]!;
  Parser<dynamic> get strikeWave => _l["strikeWave"]!;
  Parser<dynamic> get emojiCode => _l["emojiCode"]!;
  Parser<dynamic> get mathBlock => _l["mathBlock"]!;
  Parser<dynamic> get centerTag => _l["centerTag"]!;
  Parser<dynamic> get plainTag => _l["plainTag"]!;
  Parser<dynamic> get inlineCode => _l["inlineCode"]!;
  Parser<dynamic> get mathInline => _l["mathInline"]!;
  Parser<dynamic> get mention => _l["mention"]!;
  Parser<dynamic> get fn => _l["fn"]!;
  Parser<dynamic> get hashTag => _l["hashtag"]!;
  Parser<dynamic> get link => _l["link"]!;
  Parser<dynamic> get url => _l["url"]!;
  Parser<dynamic> get urlAlt => _l["urlAlt"]!;
  Parser<dynamic> get unicodeEmoji => _l["unicodeEmoji"]!;
  Parser<dynamic> get search => _l["search"]!;

  Language() {
    _l = createLanguage({
      "full": () => alt([
            unicodeEmoji,
            centerTag,
            smallTag,
            plainTag,
            boldTag,
            italicTag,
            strikeTag,
            urlAlt,
            big,
            boldAsta,
            italicAsta,
            boldUnder,
            italicUnder,
            codeBlock,
            inlineCode,
            quote,
            mathBlock,
            mathInline,
            strikeWave,
            fn,
            mention,
            hashTag,
            emojiCode,
            link,
            url,
            search,
            text,
          ]),
      "simple": () => alt([unicodeEmoji, emojiCode, plainTag, text]),
      "inline": () => alt([
            unicodeEmoji,
            smallTag,
            plainTag,
            boldTag,
            italicTag,
            strikeTag,
            urlAlt,
            big,
            boldAsta,
            italicAsta,
            boldUnder,
            italicUnder,
            inlineCode,
            mathInline,
            strikeWave,
            fn,
            mention,
            hashTag,
            emojiCode,
            link,
            url,
            text,
          ]),
      "quote": () {
        final lines = seq(
          [
            str(">"),
            space.option(),
            seq([notMatch(newLine), char], select: 1).many(0).text(),
          ],
          select: 2,
        ).sep(newLine, 1);

        final parser = seq(
          [
            newLine.option(),
            newLine.option(),
            lineBegin,
            lines,
            newLine.option(),
            newLine.option(),
          ],
          select: 3,
        );

        return Parser<MfmQuote>(
          handler: (input, index, state) {
            final result = parser.handler(input, index, state);
            if (result is! Success) {
              return failure();
            }

            final Success(
              value: List<dynamic> contents,
              index: quoteIndex,
            ) = result;

            if (contents.length == 1 && (contents[0] as String).isEmpty) {
              return failure();
            }

            final contentParser = nest(fullParser).many(0);
            final contentResult =
                contentParser.handler(contents.join("\n"), 0, state);

            if (contentResult is! Success<List<dynamic>>) {
              return failure();
            }

            return success(
              quoteIndex,
              MfmQuote(children: mergeText(contentResult.value)),
            );
          },
        );
      },
      "codeBlock": () {
        final mark = str("```");
        return seq([
          newLine.option(),
          lineBegin,
          mark,
          seq([notMatch(newLine), char], select: 1).many(0),
          newLine,
          seq(
            [
              notMatch(seq([newLine, mark, lineEnd])),
              char,
            ],
            select: 1,
          ).many(1),
          newLine,
          mark,
          lineEnd,
          newLine.option(),
        ]).map((result) {
          final lang =
              ((result as List<dynamic>)[3] as List<dynamic>).join().trim();
          final code = (result[5] as List<dynamic>).join();

          return MfmCodeBlock(code, lang.isNotEmpty ? lang : null);
        });
      },
      "mathBlock": () {
        final open = str(r"\[");
        final close = str(r"\]");

        return seq(
          [
            newLine.option(),
            lineBegin,
            open,
            newLine.option(),
            seq(
              [
                notMatch(seq([newLine.option(), close])),
                char,
              ],
              select: 1,
            ).many(1),
            newLine.option(),
            close,
            lineEnd,
            newLine.option(),
          ],
          select: 4,
        ).map((result) => MfmMathBlock((result as List<dynamic>).join()));
      },
      "centerTag": () {
        final open = str("<center>");
        final close = str("</center>");

        return seq(
          [
            newLine.option(),
            lineBegin,
            open,
            newLine.option(),
            seq(
              [
                notMatch(seq([newLine.option(), close])),
                nest(inline),
              ],
              select: 1,
            ).many(1),
            newLine.option(),
            close,
            lineEnd,
            newLine.option(),
          ],
          select: 4,
        ).map(
          (result) => MfmCenter(
            children: mergeText(result as List<dynamic>).cast<MfmInline>(),
          ),
        );
      },
      "big": () {
        final mark = str("***");
        return seqOrText([
          mark,
          seq([notMatch(mark), nest(inline)], select: 1).many(1),
          mark,
        ]).map((result) {
          if (result is String) {
            return result;
          }
          return MfmFn(
            name: "tada",
            args: {},
            children: mergeText((result as List<dynamic>)[1] as List<dynamic>),
          );
        });
      },
      "text": () => char,
      "boldAsta": () {
        final mark = str("**");
        return seqOrText([
          mark,
          seq([notMatch(mark), nest(inline)], select: 1).many(1),
          mark,
        ]).map((result) {
          if (result is String) return result;
          return MfmBold(
            mergeText((result as List<dynamic>)[1] as List<dynamic>)
                .cast<MfmInline>(),
          );
        });
      },
      "boldTag": () {
        final open = str("<b>");
        final close = str("</b>");

        return seqOrText([
          open,
          seq([notMatch(close), nest(inline)], select: 1).many(1),
          close,
        ]).map((result) {
          if (result is String) return result;
          return MfmBold(
            mergeText((result as List<dynamic>)[1] as List<dynamic>)
                .cast<MfmInline>(),
          );
        });
      },
      "boldUnder": () {
        final mark = str("__");
        return seq(
          [
            mark,
            alt([alphaAndNum, space]).many(1),
            mark,
          ],
          select: 1,
        ).map((result) => MfmBold([MfmText((result as List<String>).join())]));
      },
      "smallTag": () {
        final open = str("<small>");
        final close = str("</small>");
        return seqOrText([
          open,
          seq([notMatch(close), nest(inline)], select: 1).many(1),
          close,
        ]).map((result) {
          if (result is String) return result;
          return MfmSmall(
            mergeText((result as List<dynamic>)[1] as List<dynamic>)
                .cast<MfmInline>(),
          );
        });
      },
      "italicTag": () {
        final open = str("<i>");
        final close = str("</i>");
        return seqOrText([
          open,
          seq([notMatch(close), nest(inline)], select: 1).many(1),
          close,
        ]).map((result) {
          if (result is String) return result;
          return MfmItalic(
            mergeText((result as List<dynamic>)[1] as List<dynamic>)
                .cast<MfmInline>(),
          );
        });
      },
      "italicAsta": () {
        final mark = str("*");
        final parser = seq(
          [
            mark,
            alt([alphaAndNum, space]).many(1),
            mark,
          ],
          select: 1,
        );
        return Parser<MfmItalic>(
          handler: (input, index, state) {
            final result = parser.handler(input, index, state);
            if (result is! Success) {
              return failure();
            }
            final beforeStr = input.slice(0, index);
            if (RegExp(r"[a-zA-Z0-9]$").hasMatch(beforeStr)) {
              return failure();
            }
            final Success(:List<String> value, index: resultIndex) = result;
            return success(
              resultIndex,
              MfmItalic([MfmText(value.join())]),
            );
          },
        );
      },
      "italicUnder": () {
        final mark = str("_");
        final parser = seq(
          [
            mark,
            alt([alphaAndNum, space]).many(1),
            mark,
          ],
          select: 1,
        );

        return Parser<MfmItalic>(
          handler: (input, index, state) {
            final result = parser.handler(input, index, state);
            if (result is! Success) {
              return failure();
            }
            final beforeStr = input.slice(0, index);
            if (RegExp(r"[a-zA-Z0-9]$").hasMatch(beforeStr)) {
              return failure();
            }
            final Success(:List<String> value, index: resultIndex) = result;
            return success(
              resultIndex,
              MfmItalic([MfmText(value.join())]),
            );
          },
        );
      },
      "strikeTag": () {
        final open = str("<s>");
        final close = str("</s>");

        return seqOrText([
          open,
          seq([notMatch(close), nest(inline)], select: 1).many(1),
          close,
        ]).map((result) {
          if (result is String) {
            return result;
          }
          return MfmStrike(
            mergeText((result as List<dynamic>)[1] as List<dynamic>)
                .cast<MfmInline>(),
          );
        });
      },
      "strikeWave": () {
        final mark = str("~~");
        return seqOrText([
          mark,
          seq(
            [
              notMatch(alt([mark, newLine])),
              nest(inline),
            ],
            select: 1,
          ).many(1),
          mark,
        ]).map((result) {
          if (result is String) return result;
          return MfmStrike(
            mergeText((result as List<dynamic>)[1] as List<dynamic>)
                .cast<MfmInline>(),
          );
        });
      },
      "unicodeEmoji": () {
        return regexp(tweEmojiParser)
            .map((content) => MfmUnicodeEmoji(content));
      },
      "emojiCode": () {
        final side = notMatch(regexp(RegExp("[a-zA-Z0-9]")));
        final mark = str(":");
        return seq(
          [
            alt([lineBegin, side]),
            mark,
            regexp(RegExp("[a-zA-Z0-9_+-]+")),
            mark,
            alt([lineEnd, side]),
          ],
          select: 2,
        ).map((name) => MfmEmojiCode(name as String));
      },
      "plainTag": () {
        final open = str("<plain>");
        final close = str("</plain>");

        return seq(
          [
            open,
            newLine.option(),
            seq(
              [
                notMatch(seq([newLine.option(), close])),
                char,
              ],
              select: 1,
            ).many(1).text(),
            newLine.option(),
            close,
          ],
          select: 2,
        ).map((result) => MfmPlain(result as String));
      },
      "fn": () {
        final fnName = Parser(
          handler: (input, index, state) {
            final result =
                regexp(RegExp("[a-zA-Z0-9_]+")).handler(input, index, state);
            if (result is! Success<String>) {
              return result;
            }
            return success(result.index, result.value);
          },
        );

        final arg = seq([
          regexp(RegExp("[a-zA-Z0-9_]+")),
          seq(
            [
              str("="),
              regexp(RegExp("[a-zA-Z0-9_.-]+")),
            ],
            select: 1,
          ).option(),
        ]).map((result) {
          return (
            k: (result as List<dynamic>)[0] as String,
            v: (result[1] != null) ? result[1] as String : "",
          );
        });

        final args = seq(
          [
            str("."),
            arg.sep(str(","), 1),
          ],
          select: 1,
        ).map((pairs) {
          final result = <String, String>{};
          for (final pair in pairs as List<({String k, String v})>) {
            result[pair.k] = pair.v;
          }
          return result;
        });

        final fnClose = str("]");

        return seqOrText([
          str(r"$["),
          fnName,
          args.option(),
          str(" "),
          seq([notMatch(fnClose), nest(inline)], select: 1).many(1),
          fnClose,
        ]).map((result) {
          if (result is String) {
            return result;
          }
          final name = (result as List<dynamic>)[1];
          final args = result[2] as Map<String, String>?;
          final content = result[4] as List<dynamic>;
          return MfmFn(
            name: name as String,
            args: args ?? {},
            children: mergeText(content),
          );
        });
      },
      "inlineCode": () {
        final mark = str("`");
        return seq(
          [
            mark,
            seq(
              [
                notMatch(alt([mark, str("´"), newLine])),
                char,
              ],
              select: 1,
            ).many(1),
            mark,
          ],
          select: 1,
        ).map(
          (result) => MfmInlineCode(code: (result as List<dynamic>).join()),
        );
      },
      "mathInline": () {
        final open = str(r"\(");
        final close = str(r"\)");
        return seq(
          [
            open,
            seq(
              [
                notMatch(alt([close, newLine])),
                char,
              ],
              select: 1,
            ).many(1),
            close,
          ],
          select: 1,
        ).map(
          (result) => MfmMathInline(formula: (result as List<dynamic>).join()),
        );
      },
      "mention": () {
        final parser = seq([
          notLinkLabel,
          str("@"),
          regexp(RegExp("[a-zA-Z0-9_.-]+")),
          seq(
            [
              str("@"),
              regexp(RegExp("[a-zA-Z0-9_.-]+")),
            ],
            select: 1,
          ).option(),
        ]);

        return Parser(
          handler: (input, index, state) {
            final result = parser.handler(input, index, state);
            if (result is! Success) {
              return failure();
            }

            final beforeStr = input.slice(0, index);
            if (RegExp(r"[a-zA-Z0-9]$").hasMatch(beforeStr)) return failure();

            var invalidMention = false;
            final Success(:List<dynamic> value, index: resultIndex) = result;
            final username = value[2] as String;
            final hostname = value[3] as String?;

            var modifiedHost = hostname;
            if (hostname != null) {
              final regResult = RegExp(r"[.-]+$").firstMatch(hostname);
              if (regResult != null) {
                modifiedHost = hostname.slice(0, -1 * regResult[0]!.length);
                if (modifiedHost.isEmpty) {
                  // disallow invalid char only hostname
                  invalidMention = true;
                  modifiedHost = null;
                }
              }
            }
            // remove [.-] of tail of username
            String modifiedName = username;
            final regResult2 = RegExp(r"[.-]+$").firstMatch(username);
            if (regResult2 != null) {
              if (modifiedHost == null) {
                modifiedName = username.slice(0, -1 * regResult2[0]!.length);
              } else {
                // cannnot to remove tail of username if exist hostname
                invalidMention = true;
              }
            }
            // disallow [.-] of head of username
            if (modifiedName.isEmpty ||
                RegExp("^[.-]").hasMatch(modifiedName)) {
              invalidMention = true;
            }
            // disallow [.-] of head of hostname
            if (modifiedHost != null &&
                RegExp("^[.-]").hasMatch(modifiedHost)) {
              invalidMention = true;
            }
            // generate a text if mention is invalid
            if (invalidMention) {
              return success(resultIndex, input.slice(index, resultIndex));
            }
            final acct = modifiedHost != null
                ? "@$modifiedName@$modifiedHost"
                : "@$modifiedName";
            return success(
              index + acct.length,
              MfmMention(modifiedName, modifiedHost, acct),
            );
          },
        );
      },
      "hashtag": () {
        final mark = str("#");
        final hashTagChar = seq(
          [
            notMatch(
              alt([
                regexp(RegExp(r"""[ \u3000\t.,!?'"#:/[\]【】()「」（）<>]""")),
                space,
                newLine,
              ]),
            ),
            char,
          ],
          select: 1,
        );
        Parser<dynamic>? innerItem;
        innerItem = lazy(
          () => alt([
            seq([
              str('('),
              nest(innerItem!, fallback: hashTagChar).many(0),
              str(')'),
            ]),
            seq([
              str('['),
              nest(innerItem, fallback: hashTagChar).many(0),
              str(']'),
            ]),
            seq([
              str('「'),
              nest(innerItem, fallback: hashTagChar).many(0),
              str('」'),
            ]),
            seq([
              str('（'),
              nest(innerItem, fallback: hashTagChar).many(0),
              str('）'),
            ]),
            hashTagChar,
          ]),
        );
        final parser = seq(
          [
            notLinkLabel,
            mark,
            innerItem.many(1).text(),
          ],
          select: 2,
        );
        return Parser(
          handler: (input, index, state) {
            final result = parser.handler(input, index, state);
            if (result is! Success) {
              return failure();
            }
            // check before
            final beforeStr = input.slice(0, index);
            if (RegExp(r"[a-zA-Z0-9]$").hasMatch(beforeStr)) {
              return failure();
            }
            final Success(:String value, index: resultIndex) = result;
            // disallow number only
            if (RegExp(r"^[0-9]+$").hasMatch(value)) {
              return failure();
            }
            return success(resultIndex, MfmHashTag(value));
          },
        );
      },
      "link": () {
        final labelInline = Parser(
          handler: (input, index, state) {
            state.linkLabel = true;
            final result = inline.handler(input, index, state);
            state.linkLabel = false;
            return result;
          },
        );
        final closeLabel = str(']');
        return seq([
          notLinkLabel,
          alt([str('?['), str('[')]),
          seq(
            [
              notMatch(alt([closeLabel, newLine])),
              nest(labelInline),
            ],
            select: 1,
          ).many(1),
          closeLabel,
          str('('),
          alt([urlAlt, url]),
          str(')'),
        ]).map((result) {
          final silent = ((result as List<dynamic>)[1] == '?[');
          final label = result[2] as List<dynamic>;
          final url = result[5] as MfmURL;
          return MfmLink(
            silent: silent,
            url: url.value,
            children: mergeText(label),
          );
        });
      },
      "url": () {
        final urlChar = regexp(RegExp(r"""[.,a-zA-Z0-9_/:%#@$&?!~=+-]"""));
        Parser<dynamic>? innerItem;
        innerItem = lazy(
          () => alt([
            seq([
              str('('),
              nest(innerItem!, fallback: urlChar).many(0),
              str(')'),
            ]),
            seq([
              str('['),
              nest(innerItem, fallback: urlChar).many(0),
              str(']'),
            ]),
            urlChar,
          ]),
        );
        final parser = seq([
          notLinkLabel,
          regexp(RegExp("https?://")),
          innerItem.many(1).text(),
        ]);
        return Parser(
          handler: (input, index, state) {
            final result = parser.handler(input, index, state);
            if (result is! Success) {
              return failure();
            }
            final Success(
              :List<dynamic> value,
              index: resultIndex,
            ) = result;
            var modifiedIndex = resultIndex;
            final schema = value[1] as String;
            var content = value[2] as String;
            // remove the ".," at the right end
            final regexpResult = RegExp(r"[.,]+$").firstMatch(content);
            if (regexpResult != null) {
              modifiedIndex -= regexpResult.group(0)!.length;
              content = content.slice(0, -1 * regexpResult.group(0)!.length);
              if (content.isEmpty) {
                return success(resultIndex, input.slice(index, resultIndex));
              }
            }
            return success(modifiedIndex, MfmURL(schema + content, false));
          },
        );
      },
      "urlAlt": () {
        final open = str('<');
        final close = str('>');
        final parser = seq([
          notLinkLabel,
          open,
          regexp(RegExp("https?://")),
          seq(
            [
              notMatch(alt([close, space])),
              char,
            ],
            select: 1,
          ).many(1),
          close,
        ]).text();
        return Parser<MfmURL>(
          handler: (input, index, state) {
            final result = parser.handler(input, index, state);
            if (result is! Success<String>) {
              return failure();
            }
            final text = result.value.slice(1, result.value.length - 1);
            return success(result.index, MfmURL(text, true));
          },
        );
      },
      "search": () {
        final button = alt([
          regexp(RegExp(r"\[(検索|search)\]", caseSensitive: false)),
          regexp(RegExp("(検索|search)", caseSensitive: false)),
        ]);

        return seq([
          newLine.option(),
          lineBegin,
          seq(
            [
              notMatch(
                alt([
                  newLine,
                  seq([space, button, lineEnd]),
                ]),
              ),
              char,
            ],
            select: 1,
          ).many(1),
          space,
          button,
          lineEnd,
          newLine.option(),
        ]).map((result) {
          final query = ((result as List<dynamic>)[2] as List<dynamic>).join();
          return MfmSearch(query, "$query${result[3]}${result[4]}");
        });
      },
    });
  }
}
