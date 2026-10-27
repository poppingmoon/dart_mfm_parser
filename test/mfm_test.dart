import 'package:mfm_parser/mfm_parser.dart' hide parse;
import 'package:mfm_parser/mfm_parser.dart' as mfm_parser;
import 'package:test/test.dart';

void main() {
  const parse = mfm_parser.parse;

  group("SimpleParser", () {
    group("text", () {
      test("basic", () {
        const input = "abc";
        const output = [MfmText(text: "abc")];
        expect(mfm_parser.parseSimple(input), orderedEquals(output));
      });

      test("ignore hashtag", () {
        const input = "abc#abc";
        const output = [MfmText(text: "abc#abc")];
        expect(mfm_parser.parseSimple(input), orderedEquals(output));
      });

      test("keycap number sign", () {
        const input = "abc#️⃣abc";
        const output = [
          MfmText(text: "abc"),
          MfmUnicodeEmoji(emoji: "#️⃣"),
          MfmText(text: "abc"),
        ];

        expect(mfm_parser.parseSimple(input), orderedEquals(output));
      });
    });

    group("emoji", () {
      test("basic", () {
        const input = ":foo:";
        const output = [MfmEmojiCode(name: "foo")];
        expect(mfm_parser.parseSimple(input), orderedEquals(output));
      });

      test("between texts", () {
        const input = "foo:bar:baz";
        const output = [MfmText(text: "foo:bar:baz")];
        expect(mfm_parser.parseSimple(input), orderedEquals(output));
      });

      test("between text 2", () {
        const input = "12:34:56";
        const output = [MfmText(text: "12:34:56")];
        expect(mfm_parser.parseSimple(input), orderedEquals(output));
      });

      test("between text 3", () {
        const input = "あ:bar:い";
        const output = [
          MfmText(text: "あ"),
          MfmEmojiCode(name: "bar"),
          MfmText(text: "い"),
        ];
        expect(mfm_parser.parseSimple(input), orderedEquals(output));
      });

      test("should not parse emojis inside <plain>", () {
        const input = "<plain>:foo:</plain>";
        const output = [MfmPlain(text: ":foo:")];
        expect(mfm_parser.parseSimple(input), orderedEquals(output));
      });

      test("ignore variation selecter", () {
        const input = "\uFE0F";
        const output = [MfmText(text: "\uFE0F")];
        expect(mfm_parser.parseSimple(input), orderedEquals(output));
      });
    });

    test("disallow other syntaxes", () {
      const input = "foo **bar** baz";
      const output = [MfmText(text: "foo **bar** baz")];
      expect(mfm_parser.parseSimple(input), orderedEquals(output));
    });
  });

  group("FullParser", () {
    group("text", () {
      test("普通のテキストを入力すると1つのテキストノードが返される", () {
        const input = "abc";
        const output = [MfmText(text: "abc")];
        expect(parse(input), orderedEquals(output));
      });
    });

    group("quote", () {
      test("1行の引用ブロックを使用できる", () {
        const input = "> abc";
        const output = [
          MfmQuote(children: [MfmText(text: "abc")]),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("複数行の引用ブロックを使用できる", () {
        const input = """
> abc
> 123
""";
        const output = [
          MfmQuote(children: [MfmText(text: "abc\n123")]),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("引用ブロックはブロックをネストできる", () {
        const input = """
> <center>
> a
> </center>
""";
        const output = [
          MfmQuote(
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
        const output = [
          MfmQuote(
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
        const output = [
          MfmQuote(children: [MfmText(text: "abc\n\n123")]),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("1行の引用ブロックを空行にはできない", () {
        const input = "> ";
        const output = [MfmText(text: "> ")];
        expect(parse(input), orderedEquals(output));
      });

      test("引用ブロックの後ろの空行は無視される", () {
        const input = """
> foo
> bar

hoge""";
        const output = [
          MfmQuote(children: [MfmText(text: "foo\nbar")]),
          MfmText(text: "hoge"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("2つの引用行の間に空行がある場合は2つの引用ブロックが生成される", () {
        const input = """
> foo

> bar

hoge""";
        const output = [
          MfmQuote(children: [MfmText(text: "foo")]),
          MfmQuote(children: [MfmText(text: "bar")]),
          MfmText(text: "hoge"),
        ];

        expect(parse(input), orderedEquals(output));
      });

      test("引用中にハッシュタグがある場合", () {
        const input = "> before #abc after";
        const output = [
          MfmQuote(
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
          const output = [MfmSearch(query: "MFM 書き方 123", content: input)];
          expect(parse(input), output);
        });
        test("[Search]", () {
          const input = "MFM 書き方 123 [Search]";
          const output = [MfmSearch(query: "MFM 書き方 123", content: input)];
          expect(parse(input), output);
        });
        test("search", () {
          const input = "MFM 書き方 123 search";
          const output = [MfmSearch(query: "MFM 書き方 123", content: input)];
          expect(parse(input), output);
        });
        test("[search]", () {
          const input = "MFM 書き方 123 [search]";
          const output = [MfmSearch(query: "MFM 書き方 123", content: input)];
          expect(parse(input), output);
        });
        test("検索", () {
          const input = "MFM 書き方 123 検索";
          const output = [MfmSearch(query: "MFM 書き方 123", content: input)];
          expect(parse(input), output);
        });
        test("[検索]", () {
          const input = "MFM 書き方 123 [検索]";
          const output = [MfmSearch(query: "MFM 書き方 123", content: input)];
          expect(parse(input), output);
        });
      });

      test("ブロックの前後にあるテキストが正しく解釈される", () {
        const input = "abc\nhoge piyo bebeyo 検索\n123";
        const output = [
          MfmText(text: "abc"),
          MfmSearch(query: "hoge piyo bebeyo", content: "hoge piyo bebeyo 検索"),
          MfmText(text: "123"),
        ];
        expect(parse(input), orderedEquals(output));
      });
    });

    group("code block", () {
      test("コードブロックを使用できる", () {
        const input = "```\nabc\n```";
        const output = [MfmCodeBlock(code: "abc")];
        expect(parse(input), orderedEquals(output));
      });

      test("コードブロックには複数行のコードを入力できる", () {
        const input = "```\na\nb\nc\n```";
        const output = [MfmCodeBlock(code: "a\nb\nc")];
        expect(parse(input), orderedEquals(output));
      });

      test("コードブロックは言語を指定できる", () {
        const input = "```js\nconst a = 1;\n```";
        const output = [MfmCodeBlock(code: "const a = 1;", lang: "js")];
        expect(parse(input), orderedEquals(output));
      });

      test("ブロックの前後にあるテキストが正しく解釈される", () {
        const input = "abc\n```\nconst abc = 1;\n```\n123";
        const output = [
          MfmText(text: "abc"),
          MfmCodeBlock(code: "const abc = 1;"),
          MfmText(text: "123"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore internal marker", () {
        const input = "```\naaa```bbb\n```";
        const output = [MfmCodeBlock(code: "aaa```bbb")];

        expect(parse(input), orderedEquals(output));
      });

      test("trim after line break", () {
        const input = "```\nfoo\n```\nbar";
        const output = [MfmCodeBlock(code: "foo"), MfmText(text: "bar")];

        expect(parse(input), orderedEquals(output));
      });

      test("ignore internal markers not at line end", () {
        const input = "```a\nb\n```c\n```d\ne\n```";
        const output = [MfmCodeBlock(code: "b\n```c\n```d\ne", lang: "a")];

        expect(parse(input), orderedEquals(output));
      });

      test("with CRLF line breaks", () {
        const input = "abc\r\n```js\r\nconst abc = 1;\r\n```\r\n123";
        const output = [
          MfmText(text: "abc"),
          MfmCodeBlock(code: "const abc = 1;", lang: "js"),
          MfmText(text: "123"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("with CR line breaks", () {
        const input = "abc\r```js\rconst abc = 1;\r```\r123";
        const output = [
          MfmText(text: "abc"),
          MfmCodeBlock(code: "const abc = 1;", lang: "js"),
          MfmText(text: "123"),
        ];
        expect(parse(input), orderedEquals(output));
      });
    });

    group("mathBlock", () {
      test("1行の数式ブロックを使用できる", () {
        const input = r"\[math1\]";
        const output = [MfmMathBlock(formula: "math1")];
        expect(parse(input), orderedEquals(output));
      });

      test("ブロックの前後にあるテキストが正しく解釈される", () {
        const input = "abc\n\\[math1\\]\n123";
        const output = [
          MfmText(text: "abc"),
          MfmMathBlock(formula: "math1"),
          MfmText(text: "123"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("行末以外に閉じタグがある場合はマッチしない", () {
        const input = r"\[aaa\]after";
        const output = [MfmText(text: r"\[aaa\]after")];
        expect(parse(input), orderedEquals(output));
      });

      test("行頭以外に開始タグがある場合はマッチしない", () {
        const input = r"before\[aaa\]";
        const output = [MfmText(text: r"before\[aaa\]")];
        expect(parse(input), orderedEquals(output));
      });

      test("with unclosed tag before", () {
        const input = "\\[a\\]b\n\\[c\\]";
        const output = [MfmText(text: r"\[a\]b"), MfmMathBlock(formula: "c")];
        expect(parse(input), orderedEquals(output));
      });
    });

    group("center", () {
      test("single text", () {
        const input = "<center>abc</center>";
        const output = [
          MfmCenter(children: [MfmText(text: "abc")]),
        ];

        expect(parse(input), orderedEquals(output));
      });

      test("multiple text", () {
        const input = "before\n<center>\nabc\n123\npiyo\n</center>\nafter";
        const output = [
          MfmText(text: "before"),
          MfmCenter(children: [MfmText(text: "abc\n123\npiyo")]),
          MfmText(text: "after"),
        ];

        expect(parse(input), orderedEquals(output));
      });

      test("with unclosed tag before", () {
        const input = "<center>a</center>b\n<center>c</center>";
        const output = [
          MfmText(text: "<center>a</center>b"),
          MfmCenter(children: [MfmText(text: "c")]),
        ];

        expect(parse(input), orderedEquals(output));
      });

      test("with close tag in plain", () {
        const input = "<center><plain></center></plain></center>";
        const output = [
          MfmCenter(children: [MfmPlain(text: "</center>")]),
        ];

        expect(parse(input), orderedEquals(output));
      });
    });

    group("emoji code", () {
      test("basic", () {
        const input = ":abc:";
        const output = [MfmEmojiCode(name: "abc")];

        expect(parse(input), orderedEquals(output));
      });
    });

    group("unicode emoji", () {
      test("basic", () {
        const input = "今起きた😇";
        const output = [MfmText(text: "今起きた"), MfmUnicodeEmoji(emoji: "😇")];
        expect(parse(input), output);
      });

      test("keycap number sign", () {
        const input = "abc#️⃣123";
        const output = [
          MfmText(text: "abc"),
          MfmUnicodeEmoji(emoji: "#️⃣"),
          MfmText(text: "123"),
        ];
        expect(parse(input), output);
      });

      test("Unicode 15.0", () {
        const input = "🫨🩷🫷🫎🪽🪻🫚🪭🪇🪯🛜";
        const output = [
          MfmUnicodeEmoji(emoji: "🫨"),
          MfmUnicodeEmoji(emoji: "🩷"),
          MfmUnicodeEmoji(emoji: "🫷"),
          MfmUnicodeEmoji(emoji: "🫎"),
          MfmUnicodeEmoji(emoji: "🪽"),
          MfmUnicodeEmoji(emoji: "🪻"),
          MfmUnicodeEmoji(emoji: "🫚"),
          MfmUnicodeEmoji(emoji: "🪭"),
          MfmUnicodeEmoji(emoji: "🪇"),
          MfmUnicodeEmoji(emoji: "🪯"),
          MfmUnicodeEmoji(emoji: "🛜"),
        ];
        expect(parse(input), output);
      });
    });

    group("big", () {
      test("basic", () {
        const input = "***abc***";
        const output = [
          MfmFn(
            name: "tada",
            args: {},
            children: [MfmText(text: "abc")],
          ),
        ];

        expect(parse(input), orderedEquals(output));
      });

      test("内容にはインライン構文を利用できる", () {
        const input = "***123**abc**123***";
        const output = [
          MfmFn(
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
        const output = [
          MfmFn(
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

      test("ignore unclosed syntax", () {
        const input = "***abc";
        const output = [MfmText(text: "***abc")];
        expect(parse(input), orderedEquals(output));
      });
    });

    group("bold tag", () {
      test("basic", () {
        const input = "<b>abc</b>";
        const output = [
          MfmBold(children: [MfmText(text: "abc")]),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("inline syntax allowed inside", () {
        const input = "<b>123~~abc~~123</b>";
        const output = [
          MfmBold(
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
        const output = [
          MfmBold(
            children: [
              MfmText(text: "123\n"),
              MfmStrike(children: [MfmText(text: "abc")]),
              MfmText(text: "\n123"),
            ],
          ),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore unclosed syntax", () {
        const input = "<b>abc";
        const output = [MfmText(text: "<b>abc")];
        expect(parse(input), orderedEquals(output));
      });
    });

    group("bold", () {
      test("basic", () {
        const input = "**abc**";
        const output = [
          MfmBold(children: [MfmText(text: "abc")]),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("内容にはインライン構文を利用できる", () {
        const input = "**123~~abc~~123**";
        const output = [
          MfmBold(
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
        const output = [
          MfmBold(
            children: [
              MfmText(text: "123\n"),
              MfmStrike(children: [MfmText(text: "abc")]),
              MfmText(text: "\n123"),
            ],
          ),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("with underscores", () {
        const input = "__abc__";
        const output = [
          MfmBold(children: [MfmText(text: "abc")]),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("with underscores (space allowed)", () {
        const input = "__a b__";
        const output = [
          MfmBold(children: [MfmText(text: "a b")]),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("with underscores (only alphanumeric and space allowed)", () {
        const input = "__a*b__";
        const output = [MfmText(text: "__a*b__")];
        expect(parse(input), orderedEquals(output));
      });
    });

    group("bold under", () {
      group("italic alt 1", () {
        test("basic", () {
          const input = "__abc__";
          const output = [
            MfmBold(children: [MfmText(text: "abc")]),
          ];
          expect(parse(input), orderedEquals(output));
        });

        test("basic 2", () {
          const input = "before __abc__ after";
          const output = [
            MfmText(text: "before "),
            MfmBold(children: [MfmText(text: "abc")]),
            MfmText(text: " after"),
          ];
          expect(parse(input), orderedEquals(output));
        });

        test("basic 3", () {
          const input = "before __a b c__ after";
          const output = [
            MfmText(text: "before "),
            MfmBold(children: [MfmText(text: "a b c")]),
            MfmText(text: " after"),
          ];
          expect(parse(input), orderedEquals(output));
        });
      });
    });

    group("small", () {
      test("basic", () {
        const input = "<small>abc</small>";
        const output = [
          MfmSmall(children: [MfmText(text: "abc")]),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("内容にはインライン構文を利用できる", () {
        const input = "<small>abc**123**abc</small>";
        const output = [
          MfmSmall(
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
        const output = [
          MfmSmall(
            children: [
              MfmText(text: "abc\n"),
              MfmBold(children: [MfmText(text: "123")]),
              MfmText(text: "\nabc"),
            ],
          ),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore unclosed syntax", () {
        const input = "<small>abc";
        const output = [MfmText(text: "<small>abc")];
        expect(parse(input), orderedEquals(output));
      });
    });

    group("italic tag", () {
      test("basic", () {
        const input = "<i>abc</i>";
        const output = [
          MfmItalic(children: [MfmText(text: "abc")]),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("内容にはインライン構文を利用できる", () {
        const input = "<i>abc**123**abc</i>";
        const output = [
          MfmItalic(
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
        const output = [
          MfmItalic(
            children: [
              MfmText(text: "abc\n"),
              MfmBold(children: [MfmText(text: "123")]),
              MfmText(text: "\nabc"),
            ],
          ),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore unclosed syntax", () {
        const input = "<i>abc";
        const output = [MfmText(text: "<i>abc")];
        expect(parse(input), orderedEquals(output));
      });
    });

    group("italic alt 1", () {
      test("basic", () {
        const input = "*abc*";
        const output = [
          MfmItalic(children: [MfmText(text: "abc")]),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("basic 2", () {
        const input = "before *abc* after";
        const output = [
          MfmText(text: "before "),
          MfmItalic(children: [MfmText(text: "abc")]),
          MfmText(text: " after"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("basic 3", () {
        const input = "before *a b c* after";
        const output = [
          MfmText(text: "before "),
          MfmItalic(children: [MfmText(text: "a b c")]),
          MfmText(text: " after"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test(
        "ignore a italic syntax if the before char is either a space nor an LF nor [^a-z0-9]i",
        () {
          const input = "before*abc*after";
          const output = [MfmText(text: "before*abc*after")];
          expect(parse(input), orderedEquals(output));

          const input2 = "あいう*abc*えお";
          const output2 = [
            MfmText(text: "あいう"),
            MfmItalic(children: [MfmText(text: "abc")]),
            MfmText(text: "えお"),
          ];
          expect(parse(input2), orderedEquals(output2));
        },
      );
    });

    group("italic alt 2", () {
      test("basic", () {
        const input = "_abc_";
        const output = [
          MfmItalic(children: [MfmText(text: "abc")]),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("basic 2", () {
        const input = "before _abc_ after";
        const output = [
          MfmText(text: "before "),
          MfmItalic(children: [MfmText(text: "abc")]),
          MfmText(text: " after"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("basic 3", () {
        const input = "before _a b c_ after";
        const output = [
          MfmText(text: "before "),
          MfmItalic(children: [MfmText(text: "a b c")]),
          MfmText(text: " after"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test(
        "ignore a italic syntax if the before char is either a space nor an LF nor [^a-z0-9]i",
        () {
          const input = "before_abc_after";
          const output = [MfmText(text: "before_abc_after")];
          expect(parse(input), orderedEquals(output));

          const input2 = "あいう_abc_えお";
          const output2 = [
            MfmText(text: "あいう"),
            MfmItalic(children: [MfmText(text: "abc")]),
            MfmText(text: "えお"),
          ];
          expect(parse(input2), orderedEquals(output2));
        },
      );
    });

    group("strike tag", () {
      test("basic", () {
        const input = "<s>foo</s>";
        const output = [
          MfmStrike(children: [MfmText(text: "foo")]),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore unclosed syntax", () {
        const input = "<s>abc";
        const output = [MfmText(text: "<s>abc")];
        expect(parse(input), orderedEquals(output));
      });
    });

    group("strike", () {
      test("basic", () {
        const input = "~~foo~~";
        const output = [
          MfmStrike(children: [MfmText(text: "foo")]),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore unclosed syntax", () {
        const input = "~~abc";
        const output = [MfmText(text: "~~abc")];
        expect(parse(input), orderedEquals(output));
      });

      test("disallow line break", () {
        const input = "~~abc\ndef~~";
        const output = [MfmText(text: "~~abc\ndef~~")];
        expect(parse(input), orderedEquals(output));
      });
    });

    group("inlineCode", () {
      test("basic", () {
        const input = '`var x = "Strawberry Crisis";`';
        const output = [MfmInlineCode(code: 'var x = "Strawberry Crisis";')];
        expect(parse(input), output);
      });

      test("disallow line break", () {
        const input = "`foo\nbar`";
        const output = [MfmText(text: "`foo\nbar`")];
        expect(parse(input), output);
      });

      test("disallow ´", () {
        const input = "`foo´bar`";
        const output = [MfmText(text: "`foo´bar`")];
        expect(parse(input), output);
      });
    });

    group("mathInline", () {
      test("basic", () {
        const input = '\\(x = {-b \\pm \\sqrt{b^2-4ac} \\over 2a}\\)';
        const output = [
          MfmMathInline(formula: 'x = {-b \\pm \\sqrt{b^2-4ac} \\over 2a}'),
        ];
        expect(parse(input), output);
      });

      test("with unclosed tag in previous line", () {
        const input = '\\(a\n\\(b\\)';
        const output = [MfmText(text: '\\(a\n'), MfmMathInline(formula: "b")];
        expect(parse(input), orderedEquals(output));
      });
    });

    group("mention", () {
      test("basic", () {
        const input = "@abc";
        const output = [MfmMention(username: "abc", acct: "@abc")];
        expect(parse(input), orderedEquals(output));
      });

      test("basic 2", () {
        const input = "before @abc after";
        const output = [
          MfmText(text: "before "),
          MfmMention(username: "abc", acct: "@abc"),
          MfmText(text: " after"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("basic remote", () {
        const input = "@abc@misskey.io";
        const output = [
          MfmMention(
            username: "abc",
            host: "misskey.io",
            acct: "@abc@misskey.io",
          ),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("basic remote 2", () {
        const input = "before @abc@misskey.io after";
        const output = [
          MfmText(text: "before "),
          MfmMention(
            username: "abc",
            host: "misskey.io",
            acct: "@abc@misskey.io",
          ),
          MfmText(text: " after"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("basic remote 3", () {
        const input = "before\n@abc@misskey.io\nafter";
        const output = [
          MfmText(text: "before\n"),
          MfmMention(
            username: "abc",
            host: "misskey.io",
            acct: "@abc@misskey.io",
          ),
          MfmText(text: "\nafter"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore format of mail address", () {
        const input = "abc@example.com";
        const output = [MfmText(text: "abc@example.com")];
        expect(parse(input), orderedEquals(output));
      });

      test("detect as a mention if the before char is [^a-z0-9]i", () {
        const input = "あいう@abc";
        const output = [
          MfmText(text: "あいう"),
          MfmMention(username: "abc", acct: "@abc"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("invalid char only username", () {
        const input = "@-";
        const output = [MfmText(text: "@-")];
        expect(parse(input), orderedEquals(output));
      });

      test("invalid char only hostname", () {
        const input = "@abc@.";
        const output = [MfmText(text: "@abc@.")];
        expect(parse(input), orderedEquals(output));
      });

      test("remove trailing periods only", () {
        const input = "@abc..def..";
        const output = [
          MfmMention(username: "abc..def", acct: "@abc..def"),
          MfmText(text: ".."),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("remove trailing periods of hostname only", () {
        const input = "@abc..def@misskey..io..";
        const output = [
          MfmMention(
            username: "abc..def",
            host: "misskey..io",
            acct: "@abc..def@misskey..io",
          ),
          MfmText(text: ".."),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("allow `-` in username", () {
        const input = "@abc-d";
        const output = [MfmMention(username: "abc-d", acct: "@abc-d")];
        expect(parse(input), orderedEquals(output));
      });

      test("allow `.` in username", () {
        const input = "@bsky.brid.gy@bsky.brid.gy";
        const output = [
          MfmMention(
            username: "bsky.brid.gy",
            host: "bsky.brid.gy",
            acct: "@bsky.brid.gy@bsky.brid.gy",
          ),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("disallow `-` in head of username", () {
        const input = "@-abc";
        const output = [MfmText(text: "@-abc")];
        expect(parse(input), orderedEquals(output));
      });

      test("disallow `-` in tail of username", () {
        const input = "@abc-";
        const output = [
          MfmMention(username: "abc", acct: "@abc"),
          MfmText(text: "-"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("allow `.` in middle of username", () {
        const input = "@a.bc";
        const output = [MfmMention(username: "a.bc", acct: "@a.bc")];
        expect(parse(input), orderedEquals(output));
      });

      test("disallow `.` in head of username", () {
        const input = "@.abc";
        const output = [MfmText(text: "@.abc")];
        expect(parse(input), orderedEquals(output));
      });

      test("disallow `.` in tail of username", () {
        const input = "@abc.";
        const output = [
          MfmMention(username: "abc", acct: "@abc"),
          MfmText(text: "."),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("disallow `.` in head of hostname", () {
        const input = "@abc@.aaa";
        const output = [MfmText(text: "@abc@.aaa")];
        expect(parse(input), orderedEquals(output));
      });

      test("disallow `.` in tail of hostname", () {
        const input = "@abc@aaa.";
        const output = [
          MfmMention(username: "abc", host: "aaa", acct: "@abc@aaa"),
          MfmText(text: "."),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("disallow `-` in head of hostname", () {
        const input = "@abc@-aaa";
        const output = [MfmText(text: "@abc@-aaa")];
        expect(parse(input), orderedEquals(output));
      });

      test("disallow `-` in tail of username", () {
        const input = "@abc@aaa-";
        const output = [
          MfmMention(username: "abc", host: "aaa", acct: "@abc@aaa"),
          MfmText(text: "-"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("disallow `-` in tail of username with hostname", () {
        const input = "@abc-@misskey.io";
        const output = [MfmText(text: "@abc-@misskey.io")];
        expect(parse(input), orderedEquals(output));
      });

      test("disallow `.` in tail of username with hostname", () {
        const input = "@abc.@misskey.io";
        const output = [MfmText(text: "@abc.@misskey.io")];
        expect(parse(input), orderedEquals(output));
      });
    });

    group("hashtag", () {
      test("basic", () {
        const input = "#abc";
        const output = [MfmHashtag(hashtag: "abc")];
        expect(parse(input), orderedEquals(output));
      });

      test("basic 2", () {
        const input = "before #abc after";
        const output = [
          MfmText(text: "before "),
          MfmHashtag(hashtag: "abc"),
          MfmText(text: " after"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("with keycap number sign", () {
        const input = "#️⃣abc123 #abc";
        const output = [
          MfmUnicodeEmoji(emoji: "#️⃣"),
          MfmText(text: "abc123 "),
          MfmHashtag(hashtag: "abc"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("with keycap number sign 2", () {
        const input = "abc\n#️⃣abc";
        const output = [
          MfmText(text: "abc\n"),
          MfmUnicodeEmoji(emoji: "#️⃣"),
          MfmText(text: "abc"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test(
        "ignore a hashtag if the before char is neither a space nor an LF nor [^a-z0-9]i",
        () {
          const input = "abc#abc";
          const output = [MfmText(text: "abc#abc")];
          expect(parse(input), orderedEquals(output));

          const input2 = "あいう#abc";
          const output2 = [MfmText(text: "あいう"), MfmHashtag(hashtag: "abc")];
          expect(parse(input2), orderedEquals(output2));
        },
      );

      test("ignore comma and period", () {
        const input = "Foo #bar, baz #piyo.";
        const output = [
          MfmText(text: "Foo "),
          MfmHashtag(hashtag: "bar"),
          MfmText(text: ", baz "),
          MfmHashtag(hashtag: "piyo"),
          MfmText(text: "."),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore exclamation mark", () {
        const input = "#Foo!";
        const output = [MfmHashtag(hashtag: "Foo"), MfmText(text: "!")];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore colon", () {
        const input = "#Foo:";
        const output = [MfmHashtag(hashtag: "Foo"), MfmText(text: ":")];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore single quote", () {
        const input = "#Foo'";
        const output = [MfmHashtag(hashtag: "Foo"), MfmText(text: "'")];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore double quote", () {
        const input = '#Foo"';
        const output = [MfmHashtag(hashtag: "Foo"), MfmText(text: '"')];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore square bracket", () {
        const input = "#Foo]";
        const output = [MfmHashtag(hashtag: "Foo"), MfmText(text: "]")];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore slash", () {
        const input = "#Foo/bar";
        const output = [MfmHashtag(hashtag: "Foo"), MfmText(text: "/bar")];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore angle bracket", () {
        const input = "#Foo<bar>";
        const output = [MfmHashtag(hashtag: "Foo"), MfmText(text: "<bar>")];
        expect(parse(input), orderedEquals(output));
      });

      test("allow including number", () {
        const input = "#foo123";
        const output = [MfmHashtag(hashtag: "foo123")];
        expect(parse(input), orderedEquals(output));
      });

      test("with brackets ()", () {
        const input = "(#foo)";
        const output = [
          MfmText(text: "("),
          MfmHashtag(hashtag: "foo"),
          MfmText(text: ")"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("with brackets 「」", () {
        const input = "「#foo」";
        const output = [
          MfmText(text: "「"),
          MfmHashtag(hashtag: "foo"),
          MfmText(text: "」"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("with mix brackets", () {
        const input = "「#foo(bar)」";
        const output = [
          MfmText(text: "「"),
          MfmHashtag(hashtag: "foo(bar)"),
          MfmText(text: "」"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("with brackets () (space before)", () {
        const input = "(bar #foo)";
        const output = [
          MfmText(text: "(bar "),
          MfmHashtag(hashtag: "foo"),
          MfmText(text: ")"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("with brackets 「」(space before)", () {
        const input = "「bar #foo」";
        const output = [
          MfmText(text: "「bar "),
          MfmHashtag(hashtag: "foo"),
          MfmText(text: "」"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("disallow number only", () {
        const input = "#123";
        const output = [MfmText(text: "#123")];
        expect(parse(input), orderedEquals(output));
      });

      test("disallow number only (with brackets)", () {
        const input = "(#123)";
        const output = [MfmText(text: "(#123)")];
        expect(parse(input), orderedEquals(output));
      });
    });

    group("url", () {
      test("basic", () {
        const input = "https://misskey.io/@ai";
        const output = [MfmUrl(url: "https://misskey.io/@ai", brackets: false)];
        expect(parse(input), orderedEquals(output));
      });

      test("with other texts", () {
        const input = "official instance: https://misskey.io/@ai.";
        const output = [
          MfmText(text: "official instance: "),
          MfmUrl(url: "https://misskey.io/@ai", brackets: false),
          MfmText(text: "."),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore trailing period", () {
        const input = "https://misskey.io/@ai.";
        const output = [
          MfmUrl(url: "https://misskey.io/@ai", brackets: false),
          MfmText(text: "."),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("disallow period only.", () {
        const input = "https://.";
        const output = [MfmText(text: "https://.")];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore trailing periods", () {
        const input = "https://misskey.io/@ai...";
        const output = [
          MfmUrl(url: "https://misskey.io/@ai", brackets: false),
          MfmText(text: "..."),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore trailing periods only", () {
        const input = "https://misskey.io/@ai...foo...";
        const output = [
          MfmUrl(url: "https://misskey.io/@ai...foo", brackets: false),
          MfmText(text: "..."),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("with comma", () {
        const input = "https://example.com/foo?bar=a,b";
        const output = [
          MfmUrl(url: "https://example.com/foo?bar=a,b", brackets: false),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore trailing comma", () {
        const input = "https://example.com/foo, bar";
        const output = [
          MfmUrl(url: "https://example.com/foo", brackets: false),
          MfmText(text: ", bar"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("with brackets", () {
        const input = "https://example.com/foo(bar)";
        const output = [
          MfmUrl(url: "https://example.com/foo(bar)", brackets: false),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore parent brackets", () {
        const input = "(https://example.com/foo)";
        const output = [
          MfmText(text: "("),
          MfmUrl(url: "https://example.com/foo", brackets: false),
          MfmText(text: ")"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore parent brackets(2)", () {
        const input = "(foo https://example.com/foo)";
        const output = [
          MfmText(text: "(foo "),
          MfmUrl(url: "https://example.com/foo", brackets: false),
          MfmText(text: ")"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore parent brackets with internal brackets", () {
        const input = "(https://example.com/foo(bar))";
        const output = [
          MfmText(text: "("),
          MfmUrl(url: "https://example.com/foo(bar)", brackets: false),
          MfmText(text: ")"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore parent []", () {
        const input = "foo [https://example.com/foo] bar";
        const output = [
          MfmText(text: "foo ["),
          MfmUrl(url: "https://example.com/foo", brackets: false),
          MfmText(text: "] bar"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore non-ascii characters contained url without angle brackets", () {
        const input =
            "https://たまにポプカルやシャマレと一緒にいることもあるどうか忘れないでほしいスズランは我らの光であり.example.com";
        const output = [
          MfmText(
            text:
                "https://たまにポプカルやシャマレと一緒にいることもあるどうか忘れないでほしいスズランは我らの光であり.example.com",
          ),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("match non-ascii characters contained url with angle brackets", () {
        const input = "<https://こいしちゃんするやつ.example.com>";
        const output = [
          MfmUrl(url: "https://こいしちゃんするやつ.example.com", brackets: true),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("with unclosed angle brackets before", () {
        const input = "<https://a <https://b>";
        const output = [
          MfmText(text: "<"),
          MfmUrl(url: "https://a", brackets: false),
          MfmText(text: " "),
          MfmUrl(url: "https://b", brackets: true),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("with unclosed angle brackets in previous line", () {
        const input = "<https://a\n<https://b>";
        const output = [MfmUrl(url: "https://a\n<https://b", brackets: true)];
        expect(parse(input), orderedEquals(output));
      });

      test("with unclosed angle brackets in bold", () {
        const input = "**<https://a <https://b>**";
        const output = [
          MfmBold(
            children: [
              MfmText(text: "<"),
              MfmUrl(url: "https://a", brackets: false),
              MfmText(text: " "),
              MfmUrl(url: "https://b", brackets: true),
            ],
          ),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("prevent xss", () {
        const input = "javascript:foo";
        const output = [MfmText(text: "javascript:foo")];
        expect(parse(input), orderedEquals(output));
      });
    });

    group("link", () {
      test("basic", () {
        const input = "[official instance](https://misskey.io/@ai).";
        const output = [
          MfmLink(
            silent: false,
            url: "https://misskey.io/@ai",
            children: [MfmText(text: "official instance")],
          ),
          MfmText(text: "."),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("silent flag", () {
        const input = "?[official instance](https://misskey.io/@ai).";
        const output = [
          MfmLink(
            silent: true,
            url: "https://misskey.io/@ai",
            children: [MfmText(text: "official instance")],
          ),
          MfmText(text: "."),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("with angle brackets url", () {
        const input = "[official instance](<https://misskey.io/@ai>).";
        const output = [
          MfmLink(
            silent: false,
            url: "https://misskey.io/@ai",
            children: [MfmText(text: "official instance")],
          ),
          MfmText(text: "."),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("prevent xss", () {
        const input = "[click here](javascript:foo)";
        const output = [MfmText(text: "[click here](javascript:foo)")];
        expect(parse(input), orderedEquals(output));
      });

      group("cannot nest a url in a link label", () {
        test("basic", () {
          const input =
              "official instance: [https://misskey.io/@ai](https://misskey.io/@ai).";
          const output = [
            MfmText(text: "official instance: "),
            MfmLink(
              silent: false,
              url: "https://misskey.io/@ai",
              children: [MfmText(text: "https://misskey.io/@ai")],
            ),
            MfmText(text: "."),
          ];
          expect(parse(input), orderedEquals(output));
        });

        test("nested", () {
          const input =
              "official instance: [https://misskey.io/@ai**https://misskey.io/@ai**](https://misskey.io/@ai).";
          const output = [
            MfmText(text: "official instance: "),
            MfmLink(
              silent: false,
              url: "https://misskey.io/@ai",
              children: [
                MfmText(text: "https://misskey.io/@ai"),
                MfmBold(children: [MfmText(text: "https://misskey.io/@ai")]),
              ],
            ),
            MfmText(text: "."),
          ];
          expect(parse(input), orderedEquals(output));
        });
      });

      group("cannot nest a link in a link label", () {
        test("basic", () {
          const input =
              "official instance: [[https://misskey.io/@ai](https://misskey.io/@ai)](https://misskey.io/@ai).";
          const output = [
            MfmText(text: "official instance: "),
            MfmLink(
              silent: false,
              url: "https://misskey.io/@ai",
              children: [MfmText(text: "[https://misskey.io/@ai")],
            ),
            MfmText(text: "]("),
            MfmUrl(url: "https://misskey.io/@ai", brackets: false),
            MfmText(text: ")."),
          ];
          expect(parse(input), orderedEquals(output));
        });

        test("nested", () {
          const input =
              "official instance: [**[https://misskey.io/@ai](https://misskey.io/@ai)**](https://misskey.io/@ai).";
          const output = [
            MfmText(text: "official instance: "),
            MfmLink(
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
            MfmText(text: "."),
          ];
          expect(parse(input), orderedEquals(output));
        });
      });

      group("cannot nest a mention in a link label", () {
        test("basic", () {
          const input = "[@example](https://example.com)";
          const output = [
            MfmLink(
              silent: false,
              url: "https://example.com",
              children: [MfmText(text: "@example")],
            ),
          ];
          expect(parse(input), orderedEquals(output));
        });

        test("nested", () {
          const input = "[@example**@example**](https://example.com)";
          const output = [
            MfmLink(
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
        const output = [
          MfmLink(
            silent: false,
            url: "https://example.com/foo(bar)",
            children: [MfmText(text: "foo")],
          ),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("with parent brackets", () {
        const input = "([foo](https://example.com/foo(bar)))";
        const output = [
          MfmText(text: "("),
          MfmLink(
            silent: false,
            url: "https://example.com/foo(bar)",
            children: [MfmText(text: "foo")],
          ),
          MfmText(text: ")"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("with brackets before", () {
        const input = "[test] foo [bar](https://example.com)";
        const output = [
          MfmText(text: "[test] foo "),
          MfmLink(
            silent: false,
            url: "https://example.com",
            children: [MfmText(text: "bar")],
          ),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test('bad url in url part', () {
        const input = "[test](http://..)";
        const output = [MfmText(text: "[test](http://..)")];
        expect(parse(input), orderedEquals(output));
      });

      test('with unclosed brackets before', () {
        const input = "[[[foo] [bar](https://example.com)";
        const output = [
          MfmText(text: "[[[foo] "),
          MfmLink(
            silent: false,
            url: "https://example.com",
            children: [MfmText(text: "bar")],
          ),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test('with unclosed brackets in label', () {
        const input = "[[[foo](https://example.com)";
        const output = [
          MfmLink(
            silent: false,
            url: "https://example.com",
            children: [MfmText(text: "[[foo")],
          ),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test('with unclosed brackets in previous line', () {
        const input = "[[foo\n?[[bar](https://example.com)";
        const output = [
          MfmText(text: "[[foo\n"),
          MfmLink(
            silent: true,
            url: "https://example.com",
            children: [MfmText(text: "[bar")],
          ),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test('with unclosed brackets in bold', () {
        const input = "**[[foo** [[bar** **[baz](https://example.com)**";
        const output = [
          MfmBold(children: [MfmText(text: "[[foo")]),
          MfmText(text: " "),
          MfmLink(
            silent: false,
            url: "https://example.com",
            children: [
              MfmText(text: "[bar"),
              MfmBold(children: [MfmText(text: " ")]),
              MfmText(text: "[baz"),
            ],
          ),
          MfmText(text: "**"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("with unclosed angle brackets in label", () {
        const input = "[<https://a <https://b>](https://c)";
        const output = [
          MfmLink(
            silent: false,
            url: "https://c",
            children: [MfmText(text: "<https://a <https://b>")],
          ),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("with unclosed angle brackets in url part", () {
        const input = "[x](<https://a <https://b>)";
        const output = [
          MfmText(text: "[x](<"),
          MfmUrl(url: "https://a", brackets: false),
          MfmText(text: " "),
          MfmUrl(url: "https://b", brackets: true),
          MfmText(text: ")"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("with unclosed brackets before", () {
        const input = "[[[foo] [bar](https://example.com)";
        const output = [
          MfmText(text: "[[[foo] "),
          MfmLink(
            silent: false,
            url: "https://example.com",
            children: [MfmText(text: "bar")],
          ),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("with unclosed brackets after hashtag", () {
        const input = r"[#a$[x";
        const output = [
          MfmText(text: "["),
          MfmHashtag(hashtag: r"a$"),
          MfmText(text: "[x"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("with unclosed brackets in label", () {
        const input = "[[[foo](https://example.com)";
        const output = [
          MfmLink(
            silent: false,
            url: "https://example.com",
            children: [MfmText(text: "[[foo")],
          ),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("with unclosed brackets in previous line", () {
        const input = "[[foo\n?[[bar](https://example.com)";
        const output = [
          MfmText(text: "[[foo\n"),
          MfmLink(
            silent: true,
            url: "https://example.com",
            children: [MfmText(text: "[bar")],
          ),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("with unclosed brackets in bold", () {
        const input = "**[[foo** [[bar** **[baz](https://example.com)**";
        const output = [
          MfmBold(children: [MfmText(text: "[[foo")]),
          MfmText(text: " "),
          MfmLink(
            silent: false,
            url: "https://example.com",
            children: [
              MfmText(text: "[bar"),
              MfmBold(children: [MfmText(text: " ")]),
              MfmText(text: "[baz"),
            ],
          ),
          MfmText(text: "**"),
        ];
        expect(parse(input), orderedEquals(output));
      });
    });

    group("fn", () {
      test("basic", () {
        const input = r"$[tada abc]";
        const output = [
          MfmFn(
            name: "tada",
            args: {},
            children: [MfmText(text: "abc")],
          ),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("with a string arguments", () {
        const input = r"$[spin.speed=1.1s a]";
        const output = [
          MfmFn(
            name: "spin",
            args: {"speed": "1.1s"},
            children: [MfmText(text: "a")],
          ),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("with a string arguments 2", () {
        const input = r"$[position.x=-3 a]";
        const output = [
          MfmFn(
            name: "position",
            args: {"x": "-3"},
            children: [MfmText(text: "a")],
          ),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("invalid fn name", () {
        const input = r"$[関数 text]";
        const output = [MfmText(text: r"$[関数 text]")];
        expect(parse(input), orderedEquals(output));
      });

      test("nest", () {
        const input = r"$[spin.speed=1.1s $[shake a]]";
        const output = [
          MfmFn(
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
        const output = [
          MfmText(text: "a\n"),
          MfmPlain(text: "**Hello**\nworld"),
          MfmText(text: "\nb"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("single line", () {
        const input = "a\n<plain>**Hello** world</plain>\nb";
        const output = [
          MfmText(text: "a\n"),
          MfmPlain(text: "**Hello** world"),
          MfmText(text: "\nb"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("with unclosed tag before", () {
        const input = "<plain>a\n<plain>b</plain>";
        const output = [MfmPlain(text: "a\n<plain>b")];
        expect(parse(input), orderedEquals(output));
      });
    });

    group("nesting limit", () {
      group("quote", () {
        test("basic", () {
          const input = ">>> abc";
          const output = [
            MfmQuote(
              children: [
                MfmQuote(children: [MfmText(text: "> abc")]),
              ],
            ),
          ];
          expect(parse(input, nestLimit: 2), orderedEquals(output));
        });

        test("basic 2", () {
          const input = ">> **abc**";
          const output = [
            MfmQuote(
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
        const output = [
          MfmBold(
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
          const output = [
            MfmItalic(
              children: [
                MfmItalic(children: [MfmText(text: "**abc**")]),
              ],
            ),
          ];
          expect(parse(input, nestLimit: 2), orderedEquals(output));
        });

        test("tag", () {
          const input = "<i><i><b>abc</b></i></i>";
          const output = [
            MfmItalic(
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
        const output = [
          MfmItalic(
            children: [
              MfmItalic(children: [MfmText(text: "<small>abc</small>")]),
            ],
          ),
        ];
        expect(parse(input, nestLimit: 2), orderedEquals(output));
      });

      test("italic", () {
        const input = "<b><b><i>abc</i></b></b>";
        const output = [
          MfmBold(
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
          const output = [
            MfmBold(
              children: [
                MfmBold(children: [MfmText(text: "~~abc~~")]),
              ],
            ),
          ];
          expect(parse(input, nestLimit: 2), orderedEquals(output));
        });

        test("tag", () {
          const input = "<b><b><s>abc</s></b></b>";
          const output = [
            MfmBold(
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
          const output = [
            MfmBold(children: [MfmHashtag(hashtag: "abc(xyz)")]),
          ];
          expect(parse(input, nestLimit: 2), output);

          const input2 = "<b>#abc(x(y)z)</b>";
          const output2 = [
            MfmBold(
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
          const output = [
            MfmText(text: "("),
            MfmHashtag(hashtag: "abc"),
            MfmText(text: ")"),
          ];
          expect(parse(input), orderedEquals(output));
        });

        test("outside []", () {
          const input = "[#abc]";
          const output = [
            MfmText(text: "["),
            MfmHashtag(hashtag: "abc"),
            MfmText(text: "]"),
          ];
          expect(parse(input), orderedEquals(output));
        });

        test("outside 「」", () {
          const input = "「#abc」";
          const output = [
            MfmText(text: "「"),
            MfmHashtag(hashtag: "abc"),
            MfmText(text: "」"),
          ];
          expect(parse(input), orderedEquals(output));
        });

        test("outside （）", () {
          const input = "（#abc）";
          const output = [
            MfmText(text: "（"),
            MfmHashtag(hashtag: "abc"),
            MfmText(text: "）"),
          ];
          expect(parse(input), orderedEquals(output));
        });
      });

      test("url", () {
        const input = "<b>https://example.com/abc(xyz)</b>";
        const output = [
          MfmBold(
            children: [
              MfmUrl(url: "https://example.com/abc(xyz)", brackets: false),
            ],
          ),
        ];
        expect(parse(input, nestLimit: 2), orderedEquals(output));

        const input2 = "<b>https://example.com/abc(x(y)z)</b>";
        const output2 = [
          MfmBold(
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
        const output = [
          MfmBold(
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
      const output = [
        MfmText(text: "before"),
        MfmCenter(
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
        MfmText(text: "after"),
      ];

      expect(parse(input), orderedEquals(output));
    });
  });
}
