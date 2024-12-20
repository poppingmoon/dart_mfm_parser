import 'package:mfm_parser/src/node.dart';

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
