extension StringExtension on String {
  String slice(int start, int end) {
    final realStart = start < 0 ? length + start : start;
    final realEnd = end < 0 ? length + end : end;

    return substring(realStart, realEnd);
  }
}
