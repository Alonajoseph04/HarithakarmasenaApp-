// Web implementation — uses dart:html sessionStorage for tab-isolated sessions
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void setSession(String key, String value) {
  html.window.sessionStorage[key] = value;
}

String? getSession(String key) {
  return html.window.sessionStorage[key];
}

void removeSession(String key) {
  html.window.sessionStorage.remove(key);
}
