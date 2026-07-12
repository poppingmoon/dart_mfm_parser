import 'package:mfm_parser/src/node.dart';

const _lfCode = 0x0a; // '\n'
const _crCode = 0x0d; // '\r'
const _hashCode = 0x23; // '#'
const _dollarCode = 0x24; // '$'
const _parenOpenCode = 0x28; // '('
const _parenCloseCode = 0x29; // ')'
const _asteriskCode = 0x2a; // '*'
const _digit0Code = 0x30; // '0'
const _digit9Code = 0x39; // '9'
const _colonCode = 0x3a; // ':'
const _ltCode = 0x3c; // '<'
const _gtCode = 0x3e; // '>'
const _questionCode = 0x3f; // '?'
const _atCode = 0x40; // '@'
const _upperACode = 0x41; // 'A'
const _upperHCode = 0x48; // 'H'
const _upperZCode = 0x5a; // 'Z'
const _bracketOpenCode = 0x5b; // '['
const _backslashCode = 0x5c; // '\'
const _bracketCloseCode = 0x5d; // ']'
const _underscoreCode = 0x5f; // '_'
const _backtickCode = 0x60; // '`'
const _lowerACode = 0x61; // 'a'
const _lowerHCode = 0x68; // 'h'
const _lowerZCode = 0x7a; // 'z'
const _tildeCode = 0x7e; // '~'
const _copyrightCode = 0xA9; // '©'
const _registeredCode = 0xAE; // '®'
const _bmpSymbolFirstCode = 0x2000;
const _bmpSymbolLastCode = 0x32FF;
const _highSurrogateFirstCode = 0xD800;
const _highSurrogateLastCode = 0xDBFF;
const _shibuyaCode = 0xE50A;
const _vs16Code = 0xFE0F;

bool isAlphanumeric(int code) {
  return (_digit0Code <= code && code <= _digit9Code) ||
      (_upperACode <= code && code <= _upperZCode) ||
      (_lowerACode <= code && code <= _lowerZCode);
}

bool mayBeEmojiStart(int code) {
  return (_highSurrogateFirstCode <= code && code <= _highSurrogateLastCode) ||
      (_bmpSymbolFirstCode <= code && code <= _bmpSymbolLastCode) ||
      (_digit0Code <= code && code <= _digit9Code) ||
      code == _hashCode ||
      code == _asteriskCode ||
      code == _copyrightCode ||
      code == _registeredCode ||
      code == _shibuyaCode ||
      code == _vs16Code;
}

bool isPlainChar(int code) {
  if (code
      case _lfCode ||
          _crCode ||
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
