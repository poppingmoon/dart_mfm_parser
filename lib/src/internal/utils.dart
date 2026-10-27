import 'package:mfm_parser/src/node.dart';

const _tabCode = 0x09; // '\t'
const lfCode = 0x0A; // '\n'
const crCode = 0x0D; // '\r'
const _spaceCode = 0x20; // ' '
const _exclamationMarkCode = 0x21; // '!'
const _doubleQuoteCode = 0x22; // '"'
const _hashCode = 0x23; // '#'
const _dollarCode = 0x24; // '$'
const _percentCode = 0x25; // '%'
const _andCode = 0x26; // '&'
const _singleQuoteCode = 0x27; // '''
const _parenOpenCode = 0x28; // '('
const _parenCloseCode = 0x29; // ')'
const _asteriskCode = 0x2A; // '*'
const _plusCode = 0x2B; // '+'
const _commaCode = 0x2C; // ','
const _periodCode = 0x2E; // '.'
const _slashCode = 0x2F; // '/'
const _digit0Code = 0x30; // '0'
const _digit9Code = 0x39; // '9'
const _colonCode = 0x3A; // ':'
const _ltCode = 0x3C; // '<'
const _eqCode = 0x3D; // '='
const _gtCode = 0x3E; // '>'
const _questionCode = 0x3F; // '?'
const _atCode = 0x40; // '@'
const _upperACode = 0x41; // 'A'
const _upperHCode = 0x48; // 'H'
const _upperZCode = 0x5A; // 'Z'
const _bracketOpenCode = 0x5B; // '['
const _backslashCode = 0x5C; // '\'
const _bracketCloseCode = 0x5D; // ']'
const _underscoreCode = 0x5F; // '_'
const _backtickCode = 0x60; // '`'
const _lowerACode = 0x61; // 'a'
const _lowerHCode = 0x68; // 'h'
const _lowerZCode = 0x7A; // 'z'
const _tildeCode = 0x7E; // '~'
const _copyrightCode = 0xA9; // '©'
const _registeredCode = 0xAE; // '®'
const _bmpSymbolFirstCode = 0x2000;
const _bmpSymbolLastCode = 0x2DFF;
const _ideographicSpaceCode = 0x3000; // '　'
const _cornerBracketOpenCode = 0x300C; // '「'
const _cornerBracketCloseCode = 0x300D; // '」'
const _lenticularBracketOpenCode = 0x3010; // '【'
const _lenticularBracketCloseCode = 0x3011; // '】'
const _wavyDashCode = 0x3030; // '〰'
const _partAlternationMarkCode = 0x303D; // '〽'
const _circledCongratulationCode = 0x3297; // '㊗'
const _circledSecretCode = 0x3299; // '㊙'
const _highSurrogateFirstCode = 0xD800;
const _highSurrogateLastCode = 0xDBFF;
const _shibuyaCode = 0xE50A;
const _vs16Code = 0xFE0F;
const _fullwidthParenOpenCode = 0xFF08; // '（'
const _fullwidthParenCloseCode = 0xFF09; // '）'

const _bmpSymbolEmojiCodes = {
  0x203C,
  0x2049,
  0x2122,
  0x2139,
  0x2194,
  0x2195,
  0x2196,
  0x2197,
  0x2198,
  0x2199,
  0x21A9,
  0x21AA,
  0x231A,
  0x231B,
  0x2328,
  0x23CF,
  0x23E9,
  0x23EA,
  0x23EB,
  0x23EC,
  0x23ED,
  0x23EE,
  0x23EF,
  0x23F0,
  0x23F1,
  0x23F2,
  0x23F3,
  0x23F8,
  0x23F9,
  0x23FA,
  0x24C2,
  0x25AA,
  0x25AB,
  0x25B6,
  0x25C0,
  0x25FB,
  0x25FC,
  0x25FD,
  0x25FE,
  0x2600,
  0x2601,
  0x2602,
  0x2603,
  0x2604,
  0x260E,
  0x2611,
  0x2614,
  0x2615,
  0x2618,
  0x261D,
  0x2620,
  0x2622,
  0x2623,
  0x2626,
  0x262A,
  0x262E,
  0x262F,
  0x2638,
  0x2639,
  0x263A,
  0x2640,
  0x2642,
  0x2648,
  0x2649,
  0x264A,
  0x264B,
  0x264C,
  0x264D,
  0x264E,
  0x264F,
  0x2650,
  0x2651,
  0x2652,
  0x2653,
  0x265F,
  0x2660,
  0x2663,
  0x2665,
  0x2666,
  0x2668,
  0x267B,
  0x267E,
  0x267F,
  0x2692,
  0x2693,
  0x2694,
  0x2695,
  0x2696,
  0x2697,
  0x2699,
  0x269B,
  0x269C,
  0x26A0,
  0x26A1,
  0x26A7,
  0x26AA,
  0x26AB,
  0x26B0,
  0x26B1,
  0x26BD,
  0x26BE,
  0x26C4,
  0x26C5,
  0x26C8,
  0x26CE,
  0x26CF,
  0x26D1,
  0x26D3,
  0x26D4,
  0x26E9,
  0x26EA,
  0x26F0,
  0x26F1,
  0x26F2,
  0x26F3,
  0x26F4,
  0x26F5,
  0x26F7,
  0x26F8,
  0x26F9,
  0x26FA,
  0x26FD,
  0x2702,
  0x2705,
  0x2708,
  0x2709,
  0x270A,
  0x270B,
  0x270C,
  0x270D,
  0x270F,
  0x2712,
  0x2714,
  0x2716,
  0x271D,
  0x2721,
  0x2728,
  0x2733,
  0x2734,
  0x2744,
  0x2747,
  0x274C,
  0x274E,
  0x2753,
  0x2754,
  0x2755,
  0x2757,
  0x2763,
  0x2764,
  0x2795,
  0x2796,
  0x2797,
  0x27A1,
  0x27B0,
  0x27BF,
  0x2934,
  0x2935,
  0x2B05,
  0x2B06,
  0x2B07,
  0x2B1B,
  0x2B1C,
  0x2B50,
  0x2B55,
};

bool isSpace(int code) {
  return code == _spaceCode ||
      code == _ideographicSpaceCode ||
      code == _tabCode;
}

bool isAlphanumeric(int code) {
  return (_digit0Code <= code && code <= _digit9Code) ||
      (_upperACode <= code && code <= _upperZCode) ||
      (_lowerACode <= code && code <= _lowerZCode);
}

bool isNewLine(int code) {
  return code == lfCode || code == crCode;
}

// [.,a-zA-Z0-9_/:%#@$&?!~=+-]
bool isUrlChar(int code) {
  return (_plusCode <= code && code <= _colonCode) ||
      (_questionCode <= code && code <= _upperZCode) ||
      (_lowerACode <= code && code <= _lowerZCode) ||
      code == _exclamationMarkCode ||
      code == _hashCode ||
      code == _dollarCode ||
      code == _percentCode ||
      code == _andCode ||
      code == _eqCode ||
      code == _underscoreCode ||
      code == _tildeCode;
}

// [^ \u3000\t.,!?'"#:/[\]【】()「」（）<>\n\r]
bool isHashtagChar(int code) {
  return code != _tabCode &&
      code != lfCode &&
      code != crCode &&
      code != _spaceCode &&
      code != _exclamationMarkCode &&
      code != _doubleQuoteCode &&
      code != _hashCode &&
      code != _singleQuoteCode &&
      code != _parenOpenCode &&
      code != _parenCloseCode &&
      code != _commaCode &&
      code != _periodCode &&
      code != _slashCode &&
      code != _colonCode &&
      code != _ltCode &&
      code != _gtCode &&
      code != _questionCode &&
      code != _bracketOpenCode &&
      code != _bracketCloseCode &&
      code != _ideographicSpaceCode &&
      code != _cornerBracketOpenCode &&
      code != _cornerBracketCloseCode &&
      code != _lenticularBracketOpenCode &&
      code != _lenticularBracketCloseCode &&
      code != _fullwidthParenOpenCode &&
      code != _fullwidthParenCloseCode;
}

bool mayBeEmojiStart(int code) {
  return (_highSurrogateFirstCode <= code && code <= _highSurrogateLastCode) ||
      (_bmpSymbolFirstCode <= code &&
          code <= _bmpSymbolLastCode &&
          _bmpSymbolEmojiCodes.contains(code)) ||
      (_digit0Code <= code && code <= _digit9Code) ||
      code == _hashCode ||
      code == _asteriskCode ||
      code == _copyrightCode ||
      code == _registeredCode ||
      code == _wavyDashCode ||
      code == _partAlternationMarkCode ||
      code == _circledCongratulationCode ||
      code == _circledSecretCode ||
      code == _shibuyaCode ||
      code == _vs16Code;
}

bool isPlainChar(int code) {
  if (code
      case lfCode ||
          crCode ||
          _lowerHCode ||
          _upperHCode ||
          _colonCode ||
          _atCode ||
          _hashCode ||
          _bracketOpenCode ||
          _bracketCloseCode ||
          _parenOpenCode ||
          _parenCloseCode ||
          _questionCode ||
          _backtickCode ||
          _backslashCode ||
          _dollarCode ||
          _asteriskCode ||
          _underscoreCode ||
          _ltCode ||
          _gtCode ||
          _tildeCode) {
    return false;
  }
  return !mayBeEmojiStart(code);
}

List<MfmNode> mergeText(List<dynamic> nodes) {
  final List<MfmNode> dest = <MfmNode>[];
  final List<String> storedChars = <String>[];

  void generateText() {
    if (storedChars.isNotEmpty) {
      dest.add(MfmText(text: storedChars.join()));
      storedChars.clear();
    }
  }

  for (final node in nodes) {
    if (node is String) {
      storedChars.add(node);
    } else if (node is MfmText) {
      storedChars.add(node.text);
    } else {
      generateText();
      if (node is List) {
        var str = "";
        for (final nodeElement in node) {
          if (nodeElement is String) {
            str += nodeElement;
          } else if (nodeElement is MfmNode) {
            if (str.isNotEmpty) {
              dest.add(MfmText(text: str));
            }
            str = "";
            dest.add(nodeElement);
          }
        }
        if (str != "") {
          dest.add(MfmText(text: str));
        }
      } else if (node is MfmNode) {
        dest.add(node);
      }
    }
  }
  generateText();

  return dest;
}
