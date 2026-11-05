/// A JSON object as it comes from the API.
typedef JsonMap = Map<String, dynamic>;

/// Typed, null-safe reads from API JSON, so models never repeat
/// cast-and-default code.
extension JsonReader on JsonMap {
  String readString(String key, [String fallback = '']) => switch (this[key]) {
    final String text => text,
    null => fallback,
    final Object other => other.toString(),
  };

  /// Null when missing or empty.
  String? readStringOrNull(String key) {
    final value = this[key];
    if (value == null) return null;
    final text = value.toString();
    return text.isEmpty ? null : text;
  }

  int readInt(String key, [int fallback = 0]) => switch (this[key]) {
    final int whole => whole,
    final num number => number.toInt(),
    final String text => int.tryParse(text) ?? double.tryParse(text)?.toInt() ?? fallback,
    _ => fallback,
  };

  int? readIntOrNull(String key) => this[key] == null ? null : readInt(key);

  bool readBool(String key, [bool fallback = false]) => switch (this[key]) {
    final bool flag => flag,
    final num number => number != 0,
    final String text => text == 'true' || text == '1',
    _ => fallback,
  };

  /// Timestamps are read in the device's own time zone.
  DateTime? readDate(String key) {
    final value = this[key];
    return value is String && value.isNotEmpty ? DateTime.tryParse(value)?.toLocal() : null;
  }

  JsonMap readMap(String key) => switch (this[key]) {
    final Map<String, dynamic> map => map,
    final Map map => map.cast<String, dynamic>(),
    _ => const {},
  };

  List<T> readList<T>(String key, T Function(JsonMap item) parse) => switch (this[key]) {
    final List items => [
      for (final item in items)
        if (item is Map) parse(item.cast<String, dynamic>()),
    ],
    _ => const [],
  };
}
