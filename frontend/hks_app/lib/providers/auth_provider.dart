import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/token_storage.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  Map<String, dynamic>? _user;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false; // true after loadFromStorage() completes

  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get role => _user?['role'] ?? '';
  bool get isLoggedIn => _user != null;
  bool get isInitialized => _isInitialized;

  Future<bool> loadFromStorage() async {
    final token = await TokenStorage.getAccessToken();
    if (token != null) {
      try {
        final userData = await _api.getMe();
        _user = userData;
      } catch (_) {
        await TokenStorage.removeTokens();
      }
    }
    _isInitialized = true;
    notifyListeners();
    return _user != null;
  }

  Future<bool> loginWorkerOrAdmin(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.login(username, password);
      await TokenStorage.saveTokens(
        access: data['tokens']['access'],
        refresh: data['tokens']['refresh'],
      );
      _user = data['user'];
      _isLoading = false;
      notifyListeners();
      return true;
    } on Exception catch (e) {
      _error = e.toString().contains('401') ? 'Invalid credentials' : 'Login failed. Check connection.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> sendOtp(String phone) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.sendOtp(phone);
      _isLoading = false;
      notifyListeners();
      return res;
    } on Exception catch (e) {
      final msg = e.toString();
      if (msg.contains('404')) {
        _error = 'Phone not registered';
      } else if (msg.contains('429')) {
        _error = 'Please wait 60 seconds before requesting a new OTP';
      } else {
        _error = 'Failed to send OTP. Please try again.';
      }
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> verifyOtp(String phone, String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.verifyOtp(phone, otp);
      await TokenStorage.saveTokens(
        access: data['tokens']['access'],
        refresh: data['tokens']['refresh'],
      );
      _user = data['user'];
      _isLoading = false;
      notifyListeners();
      return true;
    } on Exception catch (e) {
      final msg = e.toString();
      if (msg.contains('OTP expired')) {
        _error = 'OTP expired. Please request a new one.';
      } else {
        _error = 'Invalid OTP. Please try again.';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await TokenStorage.removeTokens();
    _user = null;
    notifyListeners();
  }
}
