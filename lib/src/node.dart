import 'package:collection/collection.dart';

/// Misskey Elements Base Node
sealed class MfmNode {
  /// if node has child, will be array.
  final List<MfmNode>? children;

  const MfmNode({this.children});
}

sealed class MfmBlock extends MfmNode {
  const MfmBlock({super.children});
}

sealed class MfmInline extends MfmNode {
  const MfmInline({super.children});
}

/// Quote Node
class MfmQuote extends MfmBlock {
  const MfmQuote({required super.children});

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MfmQuote &&
            const DeepCollectionEquality().equals(other.children, children));
  }

  @override
  int get hashCode => Object.hash(
        runtimeType,
        const DeepCollectionEquality().hash(children),
      );
}

/// Search Node
/// [query] is search query
class MfmSearch extends MfmBlock {
  final String query;
  final String content;

  const MfmSearch({
    required this.query,
    required this.content,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MfmSearch &&
            (identical(other.query, query) || other.query == query) &&
            (identical(other.content, content) || other.content == content));
  }

  @override
  int get hashCode => Object.hash(runtimeType, query, content);
}

/// Code Block Node
class MfmCodeBlock extends MfmBlock {
  final String code;
  final String? lang;

  const MfmCodeBlock({
    required this.code,
    this.lang,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MfmCodeBlock &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.lang, lang) || other.lang == lang));
  }

  @override
  int get hashCode => Object.hash(runtimeType, code, lang);
}

class MfmMathBlock extends MfmBlock {
  final String formula;

  const MfmMathBlock({required this.formula});

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MfmMathBlock &&
            (identical(other.formula, formula) || other.formula == formula));
  }

  @override
  int get hashCode => Object.hash(runtimeType, formula);
}

/// Centering Node
class MfmCenter extends MfmBlock {
  const MfmCenter({super.children});

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MfmCenter &&
            const DeepCollectionEquality().equals(other.children, children));
  }

  @override
  int get hashCode => Object.hash(
        runtimeType,
        const DeepCollectionEquality().hash(children),
      );
}

/// Unicode Emoji Node
class MfmUnicodeEmoji extends MfmInline {
  final String emoji;

  const MfmUnicodeEmoji({required this.emoji});

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MfmUnicodeEmoji &&
            (identical(other.emoji, emoji) || other.emoji == emoji));
  }

  @override
  int get hashCode => Object.hash(runtimeType, emoji);
}

/// Misskey style Emoji Node
class MfmEmojiCode extends MfmInline {
  final String name;

  const MfmEmojiCode({required this.name});

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MfmEmojiCode &&
            (identical(other.name, name) || other.name == name));
  }

  @override
  int get hashCode => Object.hash(
        runtimeType,
        const DeepCollectionEquality().hash(children),
      );
}

/// Bold Element Node
class MfmBold extends MfmInline {
  const MfmBold({required List<MfmInline> super.children});

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MfmBold &&
            const DeepCollectionEquality().equals(other.children, children));
  }

  @override
  int get hashCode => Object.hash(
        runtimeType,
        const DeepCollectionEquality().hash(children),
      );
}

/// Small Element Node
class MfmSmall extends MfmInline {
  const MfmSmall({required List<MfmInline> super.children});

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MfmSmall &&
            const DeepCollectionEquality().equals(other.children, children));
  }

  @override
  int get hashCode => Object.hash(
        runtimeType,
        const DeepCollectionEquality().hash(children),
      );
}

/// Italic Element Node
class MfmItalic extends MfmInline {
  const MfmItalic({required List<MfmInline> super.children});

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MfmItalic &&
            const DeepCollectionEquality().equals(other.children, children));
  }

  @override
  int get hashCode => Object.hash(
        runtimeType,
        const DeepCollectionEquality().hash(children),
      );
}

/// Strike Element Node
class MfmStrike extends MfmInline {
  const MfmStrike({required List<MfmInline> super.children});

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MfmStrike &&
            const DeepCollectionEquality().equals(other.children, children));
  }

  @override
  int get hashCode => Object.hash(
        runtimeType,
        const DeepCollectionEquality().hash(children),
      );
}

/// Plain Element Node
///
/// text will be unapplicated misskey element.
class MfmPlain extends MfmInline {
  final String text;

  MfmPlain({required this.text}) : super(children: [MfmText(text: text)]);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MfmPlain &&
            (identical(other.text, text) || other.text == text));
  }

  @override
  int get hashCode => Object.hash(runtimeType, text);
}

/// Misskey Style Function Node
///
/// `$[position.x=3 something]` will be
/// `MfmFn(name: position, arg: {"x": "3"}, children: MfmText(something))`
class MfmFn extends MfmInline {
  final String name;
  final Map<String, String> args;

  const MfmFn({
    required this.name,
    required this.args,
    super.children,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MfmFn &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality().equals(other.args, args) &&
            const DeepCollectionEquality().equals(other.children, children));
  }

  @override
  int get hashCode => Object.hash(
        runtimeType,
        name,
        const DeepCollectionEquality().hash(args),
        const DeepCollectionEquality().hash(children),
      );
}

/// Inline Code Node
class MfmInlineCode extends MfmInline {
  final String code;

  const MfmInlineCode({required this.code});

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MfmInlineCode &&
            (identical(other.code, code) || other.code == code));
  }

  @override
  int get hashCode => Object.hash(runtimeType, code);
}

class MfmMathInline extends MfmInline {
  final String formula;

  const MfmMathInline({required this.formula});

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MfmMathInline &&
            (identical(other.formula, formula) || other.formula == formula));
  }

  @override
  int get hashCode => Object.hash(runtimeType, formula);
}

/// Basically Text Node
class MfmText extends MfmInline {
  final String text;

  const MfmText({required this.text});

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MfmText &&
            (identical(other.text, text) || other.text == text));
  }

  @override
  int get hashCode => Object.hash(runtimeType, text);
}

/// Mention Node
///
/// `@ai` will be MfmMention(username: "ai", acct: "@ai")
///
/// `@ai@misskey.io` will be `MfmMention(username: "ai", host: "misskey.io", acct: "@ai@misskey.io")`
class MfmMention extends MfmInline {
  final String username;
  final String? host;
  final String acct;

  const MfmMention({
    required this.username,
    this.host,
    required this.acct,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MfmMention &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.host, host) || other.host == host) &&
            (identical(other.acct, acct) || other.acct == acct));
  }

  @override
  int get hashCode => Object.hash(runtimeType, username, host, acct);
}

/// Hashtag Node
class MfmHashTag extends MfmInline {
  final String hashTag;

  const MfmHashTag({required this.hashTag});

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MfmHashTag &&
            (identical(other.hashTag, hashTag) || other.hashTag == hashTag));
  }

  @override
  int get hashCode => Object.hash(runtimeType, hashTag);
}

/// Link Node
///
/// if [silent] is true, will not display url.
class MfmLink extends MfmInline {
  final String url;
  final bool silent;

  const MfmLink({
    required this.silent,
    required this.url,
    super.children,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MfmLink &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.silent, silent) || other.silent == silent));
  }

  @override
  int get hashCode => Object.hash(runtimeType, url, silent);
}

/// URL Node
///
/// if brackets is true, will display "<https://...>"
class MfmURL extends MfmInline {
  final String value;
  final bool? brackets;

  const MfmURL({
    required this.value,
    this.brackets,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MfmURL &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.brackets, brackets) ||
                other.brackets == brackets));
  }

  @override
  int get hashCode => Object.hash(runtimeType, value, brackets);
}
