final Map<String, String> _memoryStore = <String, String>{};

class SessionStorage {
  const SessionStorage._();

  static String? read(String key) => _memoryStore[key];

  static void write(String key, String value) {
    _memoryStore[key] = value;
  }

  static void remove(String key) {
    _memoryStore.remove(key);
  }
}

