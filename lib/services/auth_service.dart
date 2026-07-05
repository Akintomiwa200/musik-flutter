import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';

class AuthService extends ChangeNotifier {
  static const _loggedInKey = 'auth_logged_in';
  static const _userKey = 'auth_user';
  static const _onboardingSeenKey = 'auth_onboarding_seen';

  UserProfile? _user;
  bool _isLoggedIn = false;
  bool _onboardingSeen = false;
  bool _googleReady = false;
  String? _googleError;

  UserProfile? get user => _user;
  bool get isLoggedIn => _isLoggedIn;
  bool get onboardingSeen => _onboardingSeen;
  String? get googleError => _googleError;

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool(_loggedInKey) ?? false;
    _onboardingSeen = prefs.getBool(_onboardingSeenKey) ?? false;
    final raw = prefs.getString(_userKey);
    if (raw != null) {
      _user = UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    }
    await _initializeGoogle();
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingSeenKey, true);
    _onboardingSeen = true;
    notifyListeners();
  }

  Future<void> signUp(UserProfile profile) async {
    await _persistSignedInUser(profile);
  }

  Future<void> _persistSignedInUser(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(profile.toJson()));
    await prefs.setBool(_loggedInKey, true);
    await prefs.setBool(_onboardingSeenKey, true);
    _user = profile;
    _isLoggedIn = true;
    _onboardingSeen = true;
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

  Future<UserProfile?> signInWithGoogle() async {
    await _initializeGoogle();
    if (!_googleReady) {
      throw StateError(_googleError ?? 'Google Sign-In is not available on this device.');
    }
    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw StateError('Google Sign-In needs platform setup for this target.');
    }

    final account = await GoogleSignIn.instance.authenticate();
    final profile = UserProfile(
      email: account.email,
      password: '',
      name: account.displayName ?? account.email.split('@').first,
      gender: '',
      provider: 'google',
      photoUrl: account.photoUrl,
    );
    await _persistSignedInUser(profile);
    return profile;
  }

  Future<void> _initializeGoogle() async {
    if (_googleReady) return;
    try {
      await GoogleSignIn.instance.initialize();
      _googleReady = true;
      _googleError = null;
    } catch (e) {
      _googleReady = false;
      _googleError = 'Google Sign-In setup failed: $e';
    }
  }

  Future<void> logOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, false);
    if (_user?.provider == 'google') {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
    _isLoggedIn = false;
    notifyListeners();
  }
}
