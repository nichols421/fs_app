import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  String? _currentUser;
  bool _isLoggedIn = false;

  // Hardcoded users for POC
  final Map<String, String> _users = {
    'tech1': 'password1',
    'tech2': 'password2',
  };

  bool get isLoggedIn => _isLoggedIn;
  String? get currentUser => _currentUser;

  Future<bool> login(String username, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    if (_users.containsKey(username) && _users[username] == password) {
      _currentUser = username;
      _isLoggedIn = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _currentUser = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}