import 'package:flutter/material.dart';

enum UserRole { patient, doctor, admin }

class AuthService extends ChangeNotifier {
  bool _isAuthenticated = false;
  UserRole? _userRole;
  String? _userName;
  String? _userEmail;

  bool get isAuthenticated => _isAuthenticated;
  UserRole? get userRole => _userRole;
  String? get userName => _userName;
  String? get userEmail => _userEmail;

  Future<bool> login(String email, String password, UserRole role) async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    // Mock authentication - in real app, call your backend API
    if (password.length >= 6) {
      _isAuthenticated = true;
      _userRole = role;
      _userEmail = email;
      _userName = _getNameFromEmail(email);
      notifyListeners();
      return true;
    }
    return false;
  }

  String _getNameFromEmail(String email) {
    return email
        .split('@')[0]
        .replaceAll('.', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  void logout() {
    _isAuthenticated = false;
    _userRole = null;
    _userName = null;
    _userEmail = null;
    notifyListeners();
  }
}
