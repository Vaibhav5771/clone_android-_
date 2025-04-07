import 'package:flutter/material.dart';

class AuthState extends ChangeNotifier {
  String? _uid, _email, _username, _avatarUrl;

  String? get uid => _uid;
  String? get email => _email;
  String? get username => _username ?? _email?.split('@')[0];
  String? get avatarUrl => _avatarUrl ?? 'assets/default_avatar.png';

  void setUser(String uid, String email, String? username, String? avatarUrl) {
    _uid = uid;
    _email = email;
    _username = username;
    _avatarUrl = avatarUrl;
    notifyListeners();
  }

  void clearUser() {
    _uid = _email = _username = _avatarUrl = null;
    notifyListeners();
  }
}