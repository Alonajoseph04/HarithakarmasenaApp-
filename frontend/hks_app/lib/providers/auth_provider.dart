import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

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
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token != null) {
      try {
        final userData = await _api.getMe();
        _user = userData;
      } catch (_) {
        await prefs.remove('access_token');
        await prefs.remove('refresh_token');
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', data['tokens']['access']);
      if (data['tokens']['refresh'] != null) {
        await prefs.setString('refresh_token', data['tokens']['refresh']);
      }
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', data['tokens']['access']);
      if (data['tokens']['refresh'] != null) {
        await prefs.setString('refresh_token', data['tokens']['refresh']);
      }
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    _user = null;
    notifyListeners();
  }
}
