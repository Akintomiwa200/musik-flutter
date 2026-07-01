import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';

class AuthService extends ChangeNotifier {
  static const _loggedInKey = 'auth_logged_in';
  static const _userKey = 'auth_user';

  UserProfile? _user;
  bool _isLoggedIn = false;

  UserProfile? get user => _user;
  bool get isLoggedIn => _isLoggedIn;

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool(_loggedInKey) ?? false;
    final raw = prefs.getString(_userKey);
    if (raw != null) {
      _user = UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    }
    notifyListeners();
  }

  Future<void> signUp(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(profile.toJson()));
    await prefs.setBool(_loggedInKey, true);
    _user = profile;
    _isLoggedIn = true;
    notifyListeners();
  }

  Future<bool> logIn(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null) return false;

    final stored = UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    if (stored.email.trim().toLowerCase() == email.trim().toLowerCase() &&
        stored.password == password) {
      await prefs.setBool(_loggedInKey, true);
      _user = stored;
      _isLoggedIn = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, false);
    _isLoggedIn = false;
    notifyListeners();
  }
}
