import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// dart:html is only available on web — import it conditionally so Android builds succeed.
// ignore: uri_does_not_exist
import 'token_storage_web.dart' if (dart.library.io) 'token_storage_stub.dart' as web_storage;

class TokenStorage {
  static const String _accessKey = 'access_token';
  static const String _refreshKey = 'refresh_token';

  /// Saves the tokens to the appropriate storage
  static Future<void> saveTokens({required String access, String? refresh}) async {
    if (kIsWeb) {
      web_storage.setSession(_accessKey, access);
      if (refresh != null) web_storage.setSession(_refreshKey, refresh);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessKey, access);
      if (refresh != null) await prefs.setString(_refreshKey, refresh);
    }
  }

  /// Retrieves the access token from the appropriate storage
  static Future<String?> getAccessToken() async {
    if (kIsWeb) {
      return web_storage.getSession(_accessKey);
    } else {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_accessKey);
    }
  }

  /// Removes all tokens from storage
  static Future<void> removeTokens() async {
    if (kIsWeb) {
      web_storage.removeSession(_accessKey);
      web_storage.removeSession(_refreshKey);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessKey);
      await prefs.remove(_refreshKey);
    }
  }
}
