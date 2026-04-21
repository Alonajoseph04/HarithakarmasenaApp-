// Stub for non-web (Android/iOS/desktop) — sessionStorage is not available,
// so these are no-ops. TokenStorage uses SharedPreferences instead on these platforms.

void setSession(String key, String value) {}

String? getSession(String key) => null;

void removeSession(String key) {}
