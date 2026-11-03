// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

class SessionStorage {
  const SessionStorage._();

  static String? read(String key) {
    try {
      return html.window.localStorage[key];
    } catch (_) {
      return null;
    }
  }

  static void write(String key, String value) {
    try {
      html.window.localStorage[key] = value;
    } catch (_) {}
  }

  static void remove(String key) {
    try {
      html.window.localStorage.remove(key);
    } catch (_) {}
  }
}

