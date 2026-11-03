import 'dart:convert';
import 'dart:io';

final Map<String, String> _testMemoryStore = <String, String>{};

class SessionStorage {
  const SessionStorage._();

  static bool get _isFlutterTest =>
      Platform.environment.containsKey('FLUTTER_TEST');

  static File _storeFile() {
    return File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}agmrm_portal_session_v1.json',
    );
  }

  static Map<String, String> _loadDisk() {
    try {
      final file = _storeFile();
      if (!file.existsSync()) return <String, String>{};
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
    } catch (_) {}
    return <String, String>{};
  }

  static void _saveDisk(Map<String, String> map) {
    try {
      _storeFile().writeAsStringSync(jsonEncode(map));
    } catch (_) {}
  }

  static String? read(String key) {
    if (_isFlutterTest) return _testMemoryStore[key];
    return _loadDisk()[key];
  }

  static void write(String key, String value) {
    if (_isFlutterTest) {
      _testMemoryStore[key] = value;
      return;
    }
    final map = _loadDisk();
    map[key] = value;
    _saveDisk(map);
  }

  static void remove(String key) {
    if (_isFlutterTest) {
      _testMemoryStore.remove(key);
      return;
    }
    final map = _loadDisk();
    map.remove(key);
    _saveDisk(map);
  }
}

