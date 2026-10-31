import 'package:collection/collection.dart';

/// Misskey Elements Base Node
sealed class const MfmNode({
  /// if node has child, will be array.
  final List<MfmNode>? children,
});

sealed class const MfmBlock({super.children}) extends MfmNode;

sealed class const MfmInline({super.children}) extends MfmNode;

/// Quote Node
class const MfmQuote({required super.children}) extends MfmBlock {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MfmQuote &&
            const DeepCollectionEquality().equals(other.children, children));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(children));
}

/// Search Node
/// [query] is search query
class const MfmSearch({
  required final String query,
  required final String content,
}) extends MfmBlock {
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
class const MfmCodeBlock({required final String code, final String? lang})
    extends MfmBlock {
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

class const MfmMathBlock({required final String formula}) extends MfmBlock {
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
class const MfmCenter({super.children}) extends MfmBlock {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MfmCenter &&
            const DeepCollectionEquality().equals(other.children, children));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(children));
}

/// Unicode Emoji Node
class const MfmUnicodeEmoji({required final String emoji}) extends MfmInline {
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
class const MfmEmojiCode({required final String name}) extends MfmInline {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MfmEmojiCode &&
            (identical(other.name, name) || other.name == name));
  }

  @override
  int get hashCode => Object.hash(runtimeType, name);
}

/// Bold Element Node
class const MfmBold({required List<MfmInline> super.children})
    extends MfmInline {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MfmBold &&
            const DeepCollectionEquality().equals(other.children, children));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(children));
}

/// Small Element Node
class const MfmSmall({required List<MfmInline> super.children})
    extends MfmInline {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MfmSmall &&
            const DeepCollectionEquality().equals(other.children, children));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(children));
}

/// Italic Element Node
class const MfmItalic({required List<MfmInline> super.children})
    extends MfmInline {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MfmItalic &&
            const DeepCollectionEquality().equals(other.children, children));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(children));
}

/// Strike Element Node
class const MfmStrike({required List<MfmInline> super.children})
    extends MfmInline {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MfmStrike &&
            const DeepCollectionEquality().equals(other.children, children));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(children));
}

/// Plain Element Node
///
/// text will be unapplicated misskey element.
class const MfmPlain({required final String text}) extends MfmInline {
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
class const MfmFn({
  required final String name,
  required final Map<String, String> args,
  super.children,
}) extends MfmInline {
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
class const MfmInlineCode({required final String code}) extends MfmInline {
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

class const MfmMathInline({required final String formula}) extends MfmInline {
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
class const MfmText({required final String text}) extends MfmInline {
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
class const MfmMention({
  required final String username,
  final String? host,
  required final String acct,
}) extends MfmInline {
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
class const MfmHashtag({required final String hashtag}) extends MfmInline {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MfmHashtag &&
            (identical(other.hashtag, hashtag) || other.hashtag == hashtag));
  }

  @override
  int get hashCode => Object.hash(runtimeType, hashtag);
}

/// Link Node
///
/// if [silent] is true, will not display url.
class const MfmLink({
  required final bool silent,
  required final String url,
  super.children,
}) extends MfmInline {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MfmLink &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.silent, silent) || other.silent == silent) &&
            const DeepCollectionEquality().equals(other.children, children));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    url,
    silent,
    const DeepCollectionEquality().hash(children),
  );
}

/// URL Node
///
/// if brackets is true, will display "<https://...>"
class const MfmUrl({required final String url, final bool? brackets})
    extends MfmInline {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MfmUrl &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.brackets, brackets) ||
                other.brackets == brackets));
  }

  @override
  int get hashCode => Object.hash(runtimeType, url, brackets);
}
