import 'package:mfm_parser/src/node.dart';

const _hashCode = 0x23; // '#'
const _asteriskCode = 0x2a; // '*'
const _digit0Code = 0x30; // '0'
const _digit9Code = 0x39; // '9'
const _upperACode = 0x41; // 'A'
const _upperZCode = 0x5a; // 'Z'
const _lowerACode = 0x61; // 'a'
const _lowerZCode = 0x7a; // 'z'
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
