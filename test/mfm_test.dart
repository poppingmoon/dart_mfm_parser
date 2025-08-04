import 'package:mfm_parser/mfm_parser.dart' hide parse;
import 'package:mfm_parser/mfm_parser.dart' as mfm_parser;
import 'package:test/test.dart';

void main() {
  const parse = mfm_parser.parse;

  group("SimpleParser", () {
    group("text", () {
      test("basic", () {
        const input = "abc";
        final output = [const MfmText(text: "abc")];
        expect(mfm_parser.parseSimple(input), orderedEquals(output));
      });

      test("ignore hashtag", () {
        const input = "abc#abc";
        final output = [const MfmText(text: "abc#abc")];
        expect(mfm_parser.parseSimple(input), orderedEquals(output));
      });

      test("keycap number sign", () {
        const input = "abc#️⃣abc";
        final output = [
          const MfmText(text: "abc"),
          const MfmUnicodeEmoji(emoji: "#️⃣"),
          const MfmText(text: "abc"),
        ];

        expect(mfm_parser.parseSimple(input), orderedEquals(output));
      });
    });

    group("emoji", () {
      test("basic", () {
        const input = ":foo:";
        final output = [const MfmEmojiCode(name: "foo")];
        expect(mfm_parser.parseSimple(input), orderedEquals(output));
      });

      test("between texts", () {
        const input = "foo:bar:baz";
        final output = [const MfmText(text: "foo:bar:baz")];
        expect(mfm_parser.parseSimple(input), orderedEquals(output));
      });

      test("between text 2", () {
        const input = "12:34:56";
        final output = [const MfmText(text: "12:34:56")];
        expect(mfm_parser.parseSimple(input), orderedEquals(output));
      });

      test("between text 3", () {
        const input = "あ:bar:い";
        final output = [
          const MfmText(text: "あ"),
          const MfmEmojiCode(name: "bar"),
          const MfmText(text: "い"),
        ];
        expect(mfm_parser.parseSimple(input), orderedEquals(output));
      });

      test("should not parse emojis inside <plain>", () {
        const input = "<plain>:foo:</plain>";
        final output = [MfmPlain(text: ":foo:")];
        expect(mfm_parser.parseSimple(input), orderedEquals(output));
      });

      test("ignore variation selecter", () {
        const input = "\uFE0F";
        final output = [const MfmText(text: "\uFE0F")];
        expect(mfm_parser.parseSimple(input), orderedEquals(output));
      });
    });

    test("disallow other syntaxes", () {
      const input = "foo **bar** baz";
      final output = [const MfmText(text: "foo **bar** baz")];
      expect(mfm_parser.parseSimple(input), orderedEquals(output));
    });
  });

  group("FullParser", () {
    group("text", () {
      test("普通のテキストを入力すると1つのテキストノードが返される", () {
        const input = "abc";
        final output = [const MfmText(text: "abc")];
        expect(parse(input), orderedEquals(output));
      });
    });

    group("quote", () {
      test("1行の引用ブロックを使用できる", () {
        const input = "> abc";
        final output = [
          const MfmQuote(children: [MfmText(text: "abc")]),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("複数行の引用ブロックを使用できる", () {
        const input = """
> abc
> 123
""";
        final output = [
          const MfmQuote(children: [MfmText(text: "abc\n123")]),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("引用ブロックはブロックをネストできる", () {
        const input = """
> <center>
> a
> </center>
""";
        final output = [
          const MfmQuote(
            children: [
              MfmCenter(children: [MfmText(text: "a")]),
            ],
          ),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("引用ブロックはインライン構文を含んだブロックをネストできる", () {
        const input = """
> <center>
> I'm @ai, An bot of misskey!
> </center>
""";
        final output = [
          const MfmQuote(
            children: [
              MfmCenter(
                children: [
                  MfmText(text: "I'm "),
                  MfmMention(username: "ai", acct: "@ai"),
                  MfmText(text: ", An bot of misskey!"),
                ],
              ),
            ],
          ),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("複数行の引用ブロックでは空行を含めることができる", () {
        const input = """
> abc
>
> 123
""";
        final output = [
          const MfmQuote(children: [MfmText(text: "abc\n\n123")]),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("1行の引用ブロックを空行にはできない", () {
        const input = "> ";
        final output = [const MfmText(text: "> ")];
        expect(parse(input), orderedEquals(output));
      });

      test("引用ブロックの後ろの空行は無視される", () {
        const input = """
> foo
> bar

hoge""";
        final output = [
          const MfmQuote(children: [MfmText(text: "foo\nbar")]),
          const MfmText(text: "hoge"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("2つの引用行の間に空行がある場合は2つの引用ブロックが生成される", () {
        const input = """
> foo

> bar

hoge""";
        final output = [
          const MfmQuote(children: [MfmText(text: "foo")]),
          const MfmQuote(children: [MfmText(text: "bar")]),
          const MfmText(text: "hoge"),
        ];

        expect(parse(input), orderedEquals(output));
      });

      test("引用中にハッシュタグがある場合", () {
        const input = "> before #abc after";
        final output = [
          const MfmQuote(
            children: [
              MfmText(text: "before "),
              MfmHashtag(hashtag: "abc"),
              MfmText(text: " after"),
            ],
          ),
        ];

        expect(parse(input), orderedEquals(output));
      });
    });

    group("search", () {
      group("検索構文を使用できる", () {
        test("Search", () {
          const input = "MFM 書き方 123 Search";
          final output = [
            const MfmSearch(query: "MFM 書き方 123", content: input),
          ];
          expect(parse(input), output);
        });
        test("[Search]", () {
          const input = "MFM 書き方 123 [Search]";
          final output = [
            const MfmSearch(query: "MFM 書き方 123", content: input),
          ];
          expect(parse(input), output);
        });
        test("search", () {
          const input = "MFM 書き方 123 search";
          final output = [
            const MfmSearch(query: "MFM 書き方 123", content: input),
          ];
          expect(parse(input), output);
        });
        test("[search]", () {
          const input = "MFM 書き方 123 [search]";
          final output = [
            const MfmSearch(query: "MFM 書き方 123", content: input),
          ];
          expect(parse(input), output);
        });
        test("検索", () {
          const input = "MFM 書き方 123 検索";
          final output = [
            const MfmSearch(query: "MFM 書き方 123", content: input),
          ];
          expect(parse(input), output);
        });
        test("[検索]", () {
          const input = "MFM 書き方 123 [検索]";
          final output = [
            const MfmSearch(query: "MFM 書き方 123", content: input),
          ];
          expect(parse(input), output);
        });
      });

      test("ブロックの前後にあるテキストが正しく解釈される", () {
        const input = "abc\nhoge piyo bebeyo 検索\n123";
        final output = [
          const MfmText(text: "abc"),
          const MfmSearch(
            query: "hoge piyo bebeyo",
            content: "hoge piyo bebeyo 検索",
          ),
          const MfmText(text: "123"),
        ];
        expect(parse(input), orderedEquals(output));
      });
    });

    group("code block", () {
      test("コードブロックを使用できる", () {
        const input = "```\nabc\n```";
        final output = [const MfmCodeBlock(code: "abc")];
        expect(parse(input), orderedEquals(output));
      });

      test("コードブロックには複数行のコードを入力できる", () {
        const input = "```\na\nb\nc\n```";
        final output = [const MfmCodeBlock(code: "a\nb\nc")];
        expect(parse(input), orderedEquals(output));
      });

      test("コードブロックは言語を指定できる", () {
        const input = "```js\nconst a = 1;\n```";
        final output = [const MfmCodeBlock(code: "const a = 1;", lang: "js")];
        expect(parse(input), orderedEquals(output));
      });

      test("ブロックの前後にあるテキストが正しく解釈される", () {
        const input = "abc\n```\nconst abc = 1;\n```\n123";
        final output = [
          const MfmText(text: "abc"),
          const MfmCodeBlock(code: "const abc = 1;"),
          const MfmText(text: "123"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore internal marker", () {
        const input = "```\naaa```bbb\n```";
        final output = [const MfmCodeBlock(code: "aaa```bbb")];

        expect(parse(input), orderedEquals(output));
      });

      test("trim after line break", () {
        const input = "```\nfoo\n```\nbar";
        final output = [
          const MfmCodeBlock(code: "foo"),
          const MfmText(text: "bar"),
        ];

        expect(parse(input), orderedEquals(output));
      });
    });

    group("mathBlock", () {
      test("1行の数式ブロックを使用できる", () {
        const input = r"\[math1\]";
        final output = [const MfmMathBlock(formula: "math1")];
        expect(parse(input), orderedEquals(output));
      });

      test("ブロックの前後にあるテキストが正しく解釈される", () {
        const input = "abc\n\\[math1\\]\n123";
        final output = [
          const MfmText(text: "abc"),
          const MfmMathBlock(formula: "math1"),
          const MfmText(text: "123"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("行末以外に閉じタグがある場合はマッチしない", () {
        const input = r"\[aaa\]after";
        final output = [const MfmText(text: r"\[aaa\]after")];
        expect(parse(input), orderedEquals(output));
      });

      test("行頭以外に開始タグがある場合はマッチしない", () {
        const input = r"before\[aaa\]";
        final output = [const MfmText(text: r"before\[aaa\]")];
        expect(parse(input), orderedEquals(output));
      });
    });

    group("center", () {
      test("single text", () {
        const input = "<center>abc</center>";
        final output = [
          const MfmCenter(children: [MfmText(text: "abc")]),
        ];

        expect(parse(input), orderedEquals(output));
      });

      test("multiple text", () {
        const input = "before\n<center>\nabc\n123\npiyo\n</center>\nafter";
        final output = [
          const MfmText(text: "before"),
          const MfmCenter(children: [MfmText(text: "abc\n123\npiyo")]),
          const MfmText(text: "after"),
        ];

        expect(parse(input), orderedEquals(output));
      });
    });

    group("emoji code", () {
      test("basic", () {
        const input = ":abc:";
        final output = [const MfmEmojiCode(name: "abc")];

        expect(parse(input), orderedEquals(output));
      });
    });

    group("unicode emoji", () {
      test("basic", () {
        const input = "今起きた😇";
        final output = [
          const MfmText(text: "今起きた"),
          const MfmUnicodeEmoji(emoji: "😇"),
        ];
        expect(parse(input), output);
      });

      test("keycap number sign", () {
        const input = "abc#️⃣123";
        final output = [
          const MfmText(text: "abc"),
          const MfmUnicodeEmoji(emoji: "#️⃣"),
          const MfmText(text: "123"),
        ];
        expect(parse(input), output);
      });

      test("Unicode 15.0", () {
        const input = "🫨🩷🫷🫎🪽🪻🫚🪭🪇🪯🛜";
        final output = [
          const MfmUnicodeEmoji(emoji: "🫨"),
          const MfmUnicodeEmoji(emoji: "🩷"),
          const MfmUnicodeEmoji(emoji: "🫷"),
          const MfmUnicodeEmoji(emoji: "🫎"),
          const MfmUnicodeEmoji(emoji: "🪽"),
          const MfmUnicodeEmoji(emoji: "🪻"),
          const MfmUnicodeEmoji(emoji: "🫚"),
          const MfmUnicodeEmoji(emoji: "🪭"),
          const MfmUnicodeEmoji(emoji: "🪇"),
          const MfmUnicodeEmoji(emoji: "🪯"),
          const MfmUnicodeEmoji(emoji: "🛜"),
        ];
        expect(parse(input), output);
      });
    });

    group("big", () {
      test("basic", () {
        const input = "***abc***";
        final output = [
          const MfmFn(
            name: "tada",
            args: {},
            children: [MfmText(text: "abc")],
          ),
        ];

        expect(parse(input), orderedEquals(output));
      });

      test("内容にはインライン構文を利用できる", () {
        const input = "***123**abc**123***";
        final output = [
          const MfmFn(
            name: "tada",
            args: {},
            children: [
              MfmText(text: "123"),
              MfmBold(children: [MfmText(text: "abc")]),
              MfmText(text: "123"),
            ],
          ),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("内容は改行できる", () {
        const input = "***123\n**abc**\n123***";
        final output = [
          const MfmFn(
            name: "tada",
            args: {},
            children: [
              MfmText(text: "123\n"),
              MfmBold(children: [MfmText(text: "abc")]),
              MfmText(text: "\n123"),
            ],
          ),
        ];
        expect(parse(input), orderedEquals(output));
      });
    });

    group("bold tag", () {
      test("basic", () {
        const input = "<b>abc</b>";
        final output = [
          const MfmBold(children: [MfmText(text: "abc")]),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("inline syntax allowed inside", () {
        const input = "<b>123~~abc~~123</b>";
        final output = [
          const MfmBold(
            children: [
              MfmText(text: "123"),
              MfmStrike(children: [MfmText(text: "abc")]),
              MfmText(text: "123"),
            ],
          ),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("line breaks", () {
        const input = "<b>123\n~~abc~~\n123</b>";
        final output = [
          const MfmBold(
            children: [
              MfmText(text: "123\n"),
              MfmStrike(children: [MfmText(text: "abc")]),
              MfmText(text: "\n123"),
            ],
          ),
        ];
        expect(parse(input), orderedEquals(output));
      });
    });

    group("bold", () {
      test("basic", () {
        const input = "**abc**";
        final output = [
          const MfmBold(children: [MfmText(text: "abc")]),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("内容にはインライン構文を利用できる", () {
        const input = "**123~~abc~~123**";
        final output = [
          const MfmBold(
            children: [
              MfmText(text: "123"),
              MfmStrike(children: [MfmText(text: "abc")]),
              MfmText(text: "123"),
            ],
          ),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("内容は改行できる", () {
        const input = "**123\n~~abc~~\n123**";
        final output = [
          const MfmBold(
            children: [
              MfmText(text: "123\n"),
              MfmStrike(children: [MfmText(text: "abc")]),
              MfmText(text: "\n123"),
            ],
          ),
        ];
        expect(parse(input), orderedEquals(output));
      });
    });

    group("bold under", () {
      group("italic alt 1", () {
        test("basic", () {
          const input = "__abc__";
          final output = [
            const MfmBold(children: [MfmText(text: "abc")]),
          ];
          expect(parse(input), orderedEquals(output));
        });

        test("basic 2", () {
          const input = "before __abc__ after";
          final output = [
            const MfmText(text: "before "),
            const MfmBold(children: [MfmText(text: "abc")]),
            const MfmText(text: " after"),
          ];
          expect(parse(input), orderedEquals(output));
        });

        test("basic 3", () {
          const input = "before __a b c__ after";
          final output = [
            const MfmText(text: "before "),
            const MfmBold(children: [MfmText(text: "a b c")]),
            const MfmText(text: " after"),
          ];
          expect(parse(input), orderedEquals(output));
        });
      });
    });

    group("small", () {
      test("basic", () {
        const input = "<small>abc</small>";
        final output = [
          const MfmSmall(children: [MfmText(text: "abc")]),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("内容にはインライン構文を利用できる", () {
        const input = "<small>abc**123**abc</small>";
        final output = [
          const MfmSmall(
            children: [
              MfmText(text: "abc"),
              MfmBold(children: [MfmText(text: "123")]),
              MfmText(text: "abc"),
            ],
          ),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("内容は改行できる", () {
        const input = "<small>abc\n**123**\nabc</small>";
        final output = [
          const MfmSmall(
            children: [
              MfmText(text: "abc\n"),
              MfmBold(children: [MfmText(text: "123")]),
              MfmText(text: "\nabc"),
            ],
          ),
        ];
        expect(parse(input), orderedEquals(output));
      });
    });

    group("italic tag", () {
      test("basic", () {
        const input = "<i>abc</i>";
        final output = [
          const MfmItalic(children: [MfmText(text: "abc")]),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("内容にはインライン構文を利用できる", () {
        const input = "<i>abc**123**abc</i>";
        final output = [
          const MfmItalic(
            children: [
              MfmText(text: "abc"),
              MfmBold(children: [MfmText(text: "123")]),
              MfmText(text: "abc"),
            ],
          ),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("内容は改行できる", () {
        const input = "<i>abc\n**123**\nabc</i>";
        final output = [
          const MfmItalic(
            children: [
              MfmText(text: "abc\n"),
              MfmBold(children: [MfmText(text: "123")]),
              MfmText(text: "\nabc"),
            ],
          ),
        ];
        expect(parse(input), orderedEquals(output));
      });
    });

    group("italic alt 1", () {
      test("basic", () {
        const input = "*abc*";
        final output = [
          const MfmItalic(children: [MfmText(text: "abc")]),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("basic 2", () {
        const input = "before *abc* after";
        final output = [
          const MfmText(text: "before "),
          const MfmItalic(children: [MfmText(text: "abc")]),
          const MfmText(text: " after"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("basic 3", () {
        const input = "before *a b c* after";
        final output = [
          const MfmText(text: "before "),
          const MfmItalic(children: [MfmText(text: "a b c")]),
          const MfmText(text: " after"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test(
        "ignore a italic syntax if the before char is either a space nor an LF nor [^a-z0-9]i",
        () {
          const input = "before*abc*after";
          final output = [const MfmText(text: "before*abc*after")];
          expect(parse(input), orderedEquals(output));

          const input2 = "あいう*abc*えお";
          final output2 = [
            const MfmText(text: "あいう"),
            const MfmItalic(children: [MfmText(text: "abc")]),
            const MfmText(text: "えお"),
          ];
          expect(parse(input2), orderedEquals(output2));
        },
      );
    });

    group("italic alt 2", () {
      test("basic", () {
        const input = "_abc_";
        final output = [
          const MfmItalic(children: [MfmText(text: "abc")]),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("basic 2", () {
        const input = "before _abc_ after";
        final output = [
          const MfmText(text: "before "),
          const MfmItalic(children: [MfmText(text: "abc")]),
          const MfmText(text: " after"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("basic 3", () {
        const input = "before _a b c_ after";
        final output = [
          const MfmText(text: "before "),
          const MfmItalic(children: [MfmText(text: "a b c")]),
          const MfmText(text: " after"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test(
        "ignore a italic syntax if the before char is either a space nor an LF nor [^a-z0-9]i",
        () {
          const input = "before_abc_after";
          final output = [const MfmText(text: "before_abc_after")];
          expect(parse(input), orderedEquals(output));

          const input2 = "あいう_abc_えお";
          final output2 = [
            const MfmText(text: "あいう"),
            const MfmItalic(children: [MfmText(text: "abc")]),
            const MfmText(text: "えお"),
          ];
          expect(parse(input2), orderedEquals(output2));
        },
      );
    });

    group("strike tag", () {
      test("basic", () {
        const input = "<s>foo</s>";
        final output = [
          const MfmStrike(children: [MfmText(text: "foo")]),
        ];
        expect(parse(input), orderedEquals(output));
      });
    });

    group("strike", () {
      test("basic", () {
        const input = "~~foo~~";
        final output = [
          const MfmStrike(children: [MfmText(text: "foo")]),
        ];
        expect(parse(input), orderedEquals(output));
      });
    });

    group("inlineCode", () {
      test("basic", () {
        const input = '`var x = "Strawberry Crisis";`';
        final output = [
          const MfmInlineCode(code: 'var x = "Strawberry Crisis";'),
        ];
        expect(parse(input), output);
      });

      test("disallow line break", () {
        const input = "`foo\nbar`";
        final output = [const MfmText(text: "`foo\nbar`")];
        expect(parse(input), output);
      });

      test("disallow ´", () {
        const input = "`foo´bar`";
        final output = [const MfmText(text: "`foo´bar`")];
        expect(parse(input), output);
      });
    });

    group("mathInline", () {
      test("basic", () {
        const input = '\\(x = {-b \\pm \\sqrt{b^2-4ac} \\over 2a}\\)';
        final output = [
          const MfmMathInline(
            formula: 'x = {-b \\pm \\sqrt{b^2-4ac} \\over 2a}',
          ),
        ];
        expect(parse(input), output);
      });
    });

    group("mention", () {
      test("basic", () {
        const input = "@abc";
        final output = [const MfmMention(username: "abc", acct: "@abc")];
        expect(parse(input), orderedEquals(output));
      });

      test("basic 2", () {
        const input = "before @abc after";
        final output = [
          const MfmText(text: "before "),
          const MfmMention(username: "abc", acct: "@abc"),
          const MfmText(text: " after"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("basic remote", () {
        const input = "@abc@misskey.io";
        final output = [
          const MfmMention(
            username: "abc",
            host: "misskey.io",
            acct: "@abc@misskey.io",
          ),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("basic remote 2", () {
        const input = "before @abc@misskey.io after";
        final output = [
          const MfmText(text: "before "),
          const MfmMention(
            username: "abc",
            host: "misskey.io",
            acct: "@abc@misskey.io",
          ),
          const MfmText(text: " after"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("basic remote 3", () {
        const input = "before\n@abc@misskey.io\nafter";
        final output = [
          const MfmText(text: "before\n"),
          const MfmMention(
            username: "abc",
            host: "misskey.io",
            acct: "@abc@misskey.io",
          ),
          const MfmText(text: "\nafter"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore format of mail address", () {
        const input = "abc@example.com";
        final output = [const MfmText(text: "abc@example.com")];
        expect(parse(input), orderedEquals(output));
      });

      test("detect as a mention if the before char is [^a-z0-9]i", () {
        const input = "あいう@abc";
        final output = [
          const MfmText(text: "あいう"),
          const MfmMention(username: "abc", acct: "@abc"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("invalid char only username", () {
        const input = "@-";
        final output = [const MfmText(text: "@-")];
        expect(parse(input), orderedEquals(output));
      });

      test("invalid char only hostname", () {
        const input = "@abc@.";
        final output = [const MfmText(text: "@abc@.")];
        expect(parse(input), orderedEquals(output));
      });

      test("allow `-` in username", () {
        const input = "@abc-d";
        final output = [const MfmMention(username: "abc-d", acct: "@abc-d")];
        expect(parse(input), orderedEquals(output));
      });

      test("disallow `-` in head of username", () {
        const input = "@-abc";
        final output = [const MfmText(text: "@-abc")];
        expect(parse(input), orderedEquals(output));
      });

      test("disallow `-` in tail of username", () {
        const input = "@abc-";
        final output = [
          const MfmMention(username: "abc", acct: "@abc"),
          const MfmText(text: "-"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("allow `.` in middle of username", () {
        const input = "@a.bc";
        final output = [const MfmMention(username: "a.bc", acct: "@a.bc")];
        expect(parse(input), orderedEquals(output));
      });

      test("disallow `.` in head of username", () {
        const input = "@.abc";
        final output = [const MfmText(text: "@.abc")];
        expect(parse(input), orderedEquals(output));
      });

      test("disallow `.` in tail of username", () {
        const input = "@abc.";
        final output = [
          const MfmMention(username: "abc", acct: "@abc"),
          const MfmText(text: "."),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("disallow `.` in head of hostname", () {
        const input = "@abc@.aaa";
        final output = [const MfmText(text: "@abc@.aaa")];
        expect(parse(input), orderedEquals(output));
      });

      test("disallow `.` in tail of hostname", () {
        const input = "@abc@aaa.";
        final output = [
          const MfmMention(username: "abc", host: "aaa", acct: "@abc@aaa"),
          const MfmText(text: "."),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("disallow `-` in head of hostname", () {
        const input = "@abc@-aaa";
        final output = [const MfmText(text: "@abc@-aaa")];
        expect(parse(input), orderedEquals(output));
      });

      test("disallow `-` in tail of username", () {
        const input = "@abc@aaa-";
        final output = [
          const MfmMention(username: "abc", host: "aaa", acct: "@abc@aaa"),
          const MfmText(text: "-"),
        ];
        expect(parse(input), orderedEquals(output));
      });
    });

    group("hashtag", () {
      test("basic", () {
        const input = "#abc";
        final output = [const MfmHashtag(hashtag: "abc")];
        expect(parse(input), orderedEquals(output));
      });

      test("basic 2", () {
        const input = "before #abc after";
        final output = [
          const MfmText(text: "before "),
          const MfmHashtag(hashtag: "abc"),
          const MfmText(text: " after"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("with keycap number sign", () {
        const input = "#️⃣abc123 #abc";
        final output = [
          const MfmUnicodeEmoji(emoji: "#️⃣"),
          const MfmText(text: "abc123 "),
          const MfmHashtag(hashtag: "abc"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("with keycap number sign 2", () {
        const input = "abc\n#️⃣abc";
        final output = [
          const MfmText(text: "abc\n"),
          const MfmUnicodeEmoji(emoji: "#️⃣"),
          const MfmText(text: "abc"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test(
        "ignore a hashtag if the before char is neither a space nor an LF nor [^a-z0-9]i",
        () {
          const input = "abc#abc";
          final output = [const MfmText(text: "abc#abc")];
          expect(parse(input), orderedEquals(output));

          const input2 = "あいう#abc";
          final output2 = [
            const MfmText(text: "あいう"),
            const MfmHashtag(hashtag: "abc"),
          ];
          expect(parse(input2), orderedEquals(output2));
        },
      );

      test("ignore comma and period", () {
        const input = "Foo #bar, baz #piyo.";
        final output = [
          const MfmText(text: "Foo "),
          const MfmHashtag(hashtag: "bar"),
          const MfmText(text: ", baz "),
          const MfmHashtag(hashtag: "piyo"),
          const MfmText(text: "."),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore exclamation mark", () {
        const input = "#Foo!";
        final output = [
          const MfmHashtag(hashtag: "Foo"),
          const MfmText(text: "!"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore colon", () {
        const input = "#Foo:";
        final output = [
          const MfmHashtag(hashtag: "Foo"),
          const MfmText(text: ":"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore single quote", () {
        const input = "#Foo'";
        final output = [
          const MfmHashtag(hashtag: "Foo"),
          const MfmText(text: "'"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore double quote", () {
        const input = '#Foo"';
        final output = [
          const MfmHashtag(hashtag: "Foo"),
          const MfmText(text: '"'),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore square bracket", () {
        const input = "#Foo]";
        final output = [
          const MfmHashtag(hashtag: "Foo"),
          const MfmText(text: "]"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore slash", () {
        const input = "#Foo/bar";
        final output = [
          const MfmHashtag(hashtag: "Foo"),
          const MfmText(text: "/bar"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore angle bracket", () {
        const input = "#Foo<bar>";
        final output = [
          const MfmHashtag(hashtag: "Foo"),
          const MfmText(text: "<bar>"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("allow including number", () {
        const input = "#foo123";
        final output = [const MfmHashtag(hashtag: "foo123")];
        expect(parse(input), orderedEquals(output));
      });

      test("with brackets ()", () {
        const input = "(#foo)";
        final output = [
          const MfmText(text: "("),
          const MfmHashtag(hashtag: "foo"),
          const MfmText(text: ")"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("with brackets 「」", () {
        const input = "「#foo」";
        final output = [
          const MfmText(text: "「"),
          const MfmHashtag(hashtag: "foo"),
          const MfmText(text: "」"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("with mix brackets", () {
        const input = "「#foo(bar)」";
        final output = [
          const MfmText(text: "「"),
          const MfmHashtag(hashtag: "foo(bar)"),
          const MfmText(text: "」"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("with brackets () (space before)", () {
        const input = "(bar #foo)";
        final output = [
          const MfmText(text: "(bar "),
          const MfmHashtag(hashtag: "foo"),
          const MfmText(text: ")"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("with brackets 「」(space before)", () {
        const input = "「bar #foo」";
        final output = [
          const MfmText(text: "「bar "),
          const MfmHashtag(hashtag: "foo"),
          const MfmText(text: "」"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("disallow number only", () {
        const input = "#123";
        final output = [const MfmText(text: "#123")];
        expect(parse(input), orderedEquals(output));
      });

      test("disallow number only (with brackets)", () {
        const input = "(#123)";
        final output = [const MfmText(text: "(#123)")];
        expect(parse(input), orderedEquals(output));
      });
    });

    group("url", () {
      test("basic", () {
        const input = "https://misskey.io/@ai";
        final output = [
          const MfmUrl(url: "https://misskey.io/@ai", brackets: false),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("with other texts", () {
        const input = "official instance: https://misskey.io/@ai.";
        final output = [
          const MfmText(text: "official instance: "),
          const MfmUrl(url: "https://misskey.io/@ai", brackets: false),
          const MfmText(text: "."),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore trailing period", () {
        const input = "https://misskey.io/@ai.";
        final output = [
          const MfmUrl(url: "https://misskey.io/@ai", brackets: false),
          const MfmText(text: "."),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("disallow period only.", () {
        const input = "https://.";
        final output = [const MfmText(text: "https://.")];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore trailing periods", () {
        const input = "https://misskey.io/@ai...";
        final output = [
          const MfmUrl(url: "https://misskey.io/@ai", brackets: false),
          const MfmText(text: "..."),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("with brackets", () {
        const input = "https://example.com/foo(bar)";
        final output = [
          const MfmUrl(url: "https://example.com/foo(bar)", brackets: false),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore parent brackets", () {
        const input = "(https://example.com/foo)";
        final output = [
          const MfmText(text: "("),
          const MfmUrl(url: "https://example.com/foo", brackets: false),
          const MfmText(text: ")"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore parent brackets(2)", () {
        const input = "(foo https://example.com/foo)";
        final output = [
          const MfmText(text: "(foo "),
          const MfmUrl(url: "https://example.com/foo", brackets: false),
          const MfmText(text: ")"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore parent brackets with internal brackets", () {
        const input = "(https://example.com/foo(bar))";
        final output = [
          const MfmText(text: "("),
          const MfmUrl(url: "https://example.com/foo(bar)", brackets: false),
          const MfmText(text: ")"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore parent []", () {
        const input = "foo [https://example.com/foo] bar";
        final output = [
          const MfmText(text: "foo ["),
          const MfmUrl(url: "https://example.com/foo", brackets: false),
          const MfmText(text: "] bar"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore non-ascii characters contained url without angle brackets", () {
        const input =
            "https://たまにポプカルやシャマレと一緒にいることもあるどうか忘れないでほしいスズランは我らの光であり.example.com";
        final output = [
          const MfmText(
            text:
                "https://たまにポプカルやシャマレと一緒にいることもあるどうか忘れないでほしいスズランは我らの光であり.example.com",
          ),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("match non-ascii characters contained url with angle brackets", () {
        const input = "<https://こいしちゃんするやつ.example.com>";
        final output = [
          const MfmUrl(url: "https://こいしちゃんするやつ.example.com", brackets: true),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("prevent xss", () {
        const input = "javascript:foo";
        final output = [const MfmText(text: "javascript:foo")];
        expect(parse(input), orderedEquals(output));
      });
    });

    group("link", () {
      test("basic", () {
        const input = "[official instance](https://misskey.io/@ai).";
        final output = [
          const MfmLink(
            silent: false,
            url: "https://misskey.io/@ai",
            children: [MfmText(text: "official instance")],
          ),
          const MfmText(text: "."),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("silent flag", () {
        const input = "?[official instance](https://misskey.io/@ai).";
        final output = [
          const MfmLink(
            silent: true,
            url: "https://misskey.io/@ai",
            children: [MfmText(text: "official instance")],
          ),
          const MfmText(text: "."),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("with angle brackets url", () {
        const input = "[official instance](<https://misskey.io/@ai>).";
        final output = [
          const MfmLink(
            silent: false,
            url: "https://misskey.io/@ai",
            children: [MfmText(text: "official instance")],
          ),
          const MfmText(text: "."),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("prevent xss", () {
        const input = "[click here](javascript:foo)";
        final output = [const MfmText(text: "[click here](javascript:foo)")];
        expect(parse(input), orderedEquals(output));
      });

      group("cannot nest a url in a link label", () {
        test("basic", () {
          const input =
              "official instance: [https://misskey.io/@ai](https://misskey.io/@ai).";
          final output = [
            const MfmText(text: "official instance: "),
            const MfmLink(
              silent: false,
              url: "https://misskey.io/@ai",
              children: [MfmText(text: "https://misskey.io/@ai")],
            ),
            const MfmText(text: "."),
          ];
          expect(parse(input), orderedEquals(output));
        });

        test("nested", () {
          const input =
              "official instance: [https://misskey.io/@ai**https://misskey.io/@ai**](https://misskey.io/@ai).";
          final output = [
            const MfmText(text: "official instance: "),
            const MfmLink(
              silent: false,
              url: "https://misskey.io/@ai",
              children: [
                MfmText(text: "https://misskey.io/@ai"),
                MfmBold(children: [MfmText(text: "https://misskey.io/@ai")]),
              ],
            ),
            const MfmText(text: "."),
          ];
          expect(parse(input), orderedEquals(output));
        });
      });

      group("cannot nest a link in a link label", () {
        test("basic", () {
          const input =
              "official instance: [[https://misskey.io/@ai](https://misskey.io/@ai)](https://misskey.io/@ai).";
          final output = [
            const MfmText(text: "official instance: "),
            const MfmLink(
              silent: false,
              url: "https://misskey.io/@ai",
              children: [MfmText(text: "[https://misskey.io/@ai")],
            ),
            const MfmText(text: "]("),
            const MfmUrl(url: "https://misskey.io/@ai", brackets: false),
            const MfmText(text: ")."),
          ];
          expect(parse(input), orderedEquals(output));
        });

        test("nested", () {
          const input =
              "official instance: [**[https://misskey.io/@ai](https://misskey.io/@ai)**](https://misskey.io/@ai).";
          final output = [
            const MfmText(text: "official instance: "),
            const MfmLink(
              silent: false,
              url: "https://misskey.io/@ai",
              children: [
                MfmBold(
                  children: [
                    MfmText(
                      text: "[https://misskey.io/@ai](https://misskey.io/@ai)",
                    ),
                  ],
                ),
              ],
            ),
            const MfmText(text: "."),
          ];
          expect(parse(input), orderedEquals(output));
        });
      });

      group("cannot nest a mention in a link label", () {
        test("basic", () {
          const input = "[@example](https://example.com)";
          final output = [
            const MfmLink(
              silent: false,
              url: "https://example.com",
              children: [MfmText(text: "@example")],
            ),
          ];
          expect(parse(input), orderedEquals(output));
        });

        test("nested", () {
          const input = "[@example**@example**](https://example.com)";
          final output = [
            const MfmLink(
              silent: false,
              url: "https://example.com",
              children: [
                MfmText(text: "@example"),
                MfmBold(children: [MfmText(text: "@example")]),
              ],
            ),
          ];
          expect(parse(input), orderedEquals(output));
        });
      });

      test("with brackets", () {
        const input = "[foo](https://example.com/foo(bar))";
        final output = [
          const MfmLink(
            silent: false,
            url: "https://example.com/foo(bar)",
            children: [MfmText(text: "foo")],
          ),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("with parent brackets", () {
        const input = "([foo](https://example.com/foo(bar)))";
        final output = [
          const MfmText(text: "("),
          const MfmLink(
            silent: false,
            url: "https://example.com/foo(bar)",
            children: [MfmText(text: "foo")],
          ),
          const MfmText(text: ")"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("with brackets before", () {
        const input = "[test] foo [bar](https://example.com)";
        final output = [
          const MfmText(text: "[test] foo "),
          const MfmLink(
            silent: false,
            url: "https://example.com",
            children: [MfmText(text: "bar")],
          ),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test('bad url in url part', () {
        const input = "[test](http://..)";
        final output = [const MfmText(text: "[test](http://..)")];
        expect(parse(input), orderedEquals(output));
      });
    });

    group("fn", () {
      test("basic", () {
        const input = r"$[tada abc]";
        final output = [
          const MfmFn(
            name: "tada",
            args: {},
            children: [MfmText(text: "abc")],
          ),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("with a string arguments", () {
        const input = r"$[spin.speed=1.1s a]";
        final output = [
          const MfmFn(
            name: "spin",
            args: {"speed": "1.1s"},
            children: [MfmText(text: "a")],
          ),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("with a string arguments 2", () {
        const input = r"$[position.x=-3 a]";
        final output = [
          const MfmFn(
            name: "position",
            args: {"x": "-3"},
            children: [MfmText(text: "a")],
          ),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("invalid fn name", () {
        const input = r"$[関数 text]";
        final output = [const MfmText(text: r"$[関数 text]")];
        expect(parse(input), orderedEquals(output));
      });

      test("nest", () {
        const input = r"$[spin.speed=1.1s $[shake a]]";
        final output = [
          const MfmFn(
            name: "spin",
            args: {"speed": "1.1s"},
            children: [
              MfmFn(
                name: "shake",
                args: {},
                children: [MfmText(text: "a")],
              ),
            ],
          ),
        ];
        expect(parse(input), orderedEquals(output));
      });
    });

    group("plain", () {
      test("multiple line", () {
        const input = "a\n<plain>\n**Hello**\nworld\n</plain>\nb";
        final output = [
          const MfmText(text: "a\n"),
          MfmPlain(text: "**Hello**\nworld"),
          const MfmText(text: "\nb"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("single line", () {
        const input = "a\n<plain>**Hello** world</plain>\nb";
        final output = [
          const MfmText(text: "a\n"),
          MfmPlain(text: "**Hello** world"),
          const MfmText(text: "\nb"),
        ];
        expect(parse(input), orderedEquals(output));
      });
    });

    group("nesting limit", () {
      group("quote", () {
        test("basic", () {
          const input = ">>> abc";
          final output = [
            const MfmQuote(
              children: [
                MfmQuote(children: [MfmText(text: "> abc")]),
              ],
            ),
          ];
          expect(parse(input, nestLimit: 2), orderedEquals(output));
        });

        test("basic 2", () {
          const input = ">> **abc**";
          final output = [
            const MfmQuote(
              children: [
                MfmQuote(children: [MfmText(text: "**abc**")]),
              ],
            ),
          ];
          expect(parse(input, nestLimit: 2), orderedEquals(output));
        });
      });

      test("big", () {
        const input = "<b><b>***abc***</b></b>";
        final output = [
          const MfmBold(
            children: [
              MfmBold(children: [MfmText(text: "***abc***")]),
            ],
          ),
        ];
        expect(parse(input, nestLimit: 2), orderedEquals(output));
      });

      group("bold", () {
        test("basic", () {
          const input = "<i><i>**abc**</i></i>";
          final output = [
            const MfmItalic(
              children: [
                MfmItalic(children: [MfmText(text: "**abc**")]),
              ],
            ),
          ];
          expect(parse(input, nestLimit: 2), orderedEquals(output));
        });

        test("tag", () {
          const input = "<i><i><b>abc</b></i></i>";
          final output = [
            const MfmItalic(
              children: [
                MfmItalic(children: [MfmText(text: "<b>abc</b>")]),
              ],
            ),
          ];
          expect(parse(input, nestLimit: 2), orderedEquals(output));
        });
      });

      test("small", () {
        const input = "<i><i><small>abc</small></i></i>";
        final output = [
          const MfmItalic(
            children: [
              MfmItalic(children: [MfmText(text: "<small>abc</small>")]),
            ],
          ),
        ];
        expect(parse(input, nestLimit: 2), orderedEquals(output));
      });

      test("italic", () {
        const input = "<b><b><i>abc</i></b></b>";
        final output = [
          const MfmBold(
            children: [
              MfmBold(children: [MfmText(text: "<i>abc</i>")]),
            ],
          ),
        ];
        expect(parse(input, nestLimit: 2), orderedEquals(output));
      });

      group("strike", () {
        test("basic", () {
          const input = "<b><b>~~abc~~</b></b>";
          final output = [
            const MfmBold(
              children: [
                MfmBold(children: [MfmText(text: "~~abc~~")]),
              ],
            ),
          ];
          expect(parse(input, nestLimit: 2), orderedEquals(output));
        });

        test("tag", () {
          const input = "<b><b><s>abc</s></b></b>";
          final output = [
            const MfmBold(
              children: [
                MfmBold(children: [MfmText(text: "<s>abc</s>")]),
              ],
            ),
          ];
          expect(parse(input, nestLimit: 2), orderedEquals(output));
        });
      });

      group("hashtag", () {
        test("basic", () {
          const input = "<b>#abc(xyz)</b>";
          final output = [
            const MfmBold(children: [MfmHashtag(hashtag: "abc(xyz)")]),
          ];
          expect(parse(input, nestLimit: 2), output);

          const input2 = "<b>#abc(x(y)z)</b>";
          final output2 = [
            const MfmBold(
              children: [
                MfmHashtag(hashtag: "abc"),
                MfmText(text: "(x(y)z)"),
              ],
            ),
          ];
          expect(parse(input2, nestLimit: 2), output2);
        });

        test("outside ()", () {
          const input = "(#abc)";
          final output = [
            const MfmText(text: "("),
            const MfmHashtag(hashtag: "abc"),
            const MfmText(text: ")"),
          ];
          expect(parse(input), orderedEquals(output));
        });

        test("outside []", () {
          const input = "[#abc]";
          final output = [
            const MfmText(text: "["),
            const MfmHashtag(hashtag: "abc"),
            const MfmText(text: "]"),
          ];
          expect(parse(input), orderedEquals(output));
        });

        test("outside 「」", () {
          const input = "「#abc」";
          final output = [
            const MfmText(text: "「"),
            const MfmHashtag(hashtag: "abc"),
            const MfmText(text: "」"),
          ];
          expect(parse(input), orderedEquals(output));
        });

        test("outside ()", () {
          const input = "(#abc)";
          final output = [
            const MfmText(text: "("),
            const MfmHashtag(hashtag: "abc"),
            const MfmText(text: ")"),
          ];
          expect(parse(input), orderedEquals(output));
        });
      });

      test("url", () {
        const input = "<b>https://example.com/abc(xyz)</b>";
        final output = [
          const MfmBold(
            children: [
              MfmUrl(url: "https://example.com/abc(xyz)", brackets: false),
            ],
          ),
        ];
        expect(parse(input, nestLimit: 2), orderedEquals(output));

        const input2 = "<b>https://example.com/abc(x(y)z)</b>";
        final output2 = [
          const MfmBold(
            children: [
              MfmUrl(url: "https://example.com/abc", brackets: false),
              MfmText(text: "(x(y)z)"),
            ],
          ),
        ];
        expect(parse(input2, nestLimit: 2), output2);
      });

      test("fn", () {
        const input = r"<b><b>$[a b]</b></b>";
        final output = [
          const MfmBold(
            children: [
              MfmBold(children: [MfmText(text: r"$[a b]")]),
            ],
          ),
        ];
        expect(parse(input, nestLimit: 2), output);
      });
    });

    test("composite", () {
      const input = r"""
before
<center>
Hello $[tada everynyan! 🎉]

I'm @ai, A bot of misskey!

https://github.com/syuilo/ai
</center>
after""";
      final output = [
        const MfmText(text: "before"),
        const MfmCenter(
          children: [
            MfmText(text: "Hello "),
            MfmFn(
              name: "tada",
              args: {},
              children: [
                MfmText(text: "everynyan! "),
                MfmUnicodeEmoji(emoji: "🎉"),
              ],
            ),
            MfmText(text: "\n\nI'm "),
            MfmMention(username: "ai", acct: "@ai"),
            MfmText(text: ", A bot of misskey!\n\n"),
            MfmUrl(url: "https://github.com/syuilo/ai", brackets: false),
          ],
        ),
        const MfmText(text: "after"),
      ];

      expect(parse(input), orderedEquals(output));
    });
  });
}
