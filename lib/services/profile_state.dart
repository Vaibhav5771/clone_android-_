import 'package:flutter/material.dart';

class ProfileState extends ChangeNotifier {
  // Placeholder for profile-related state
  bool _isProfileLoaded = false;

  bool get isProfileLoaded => _isProfileLoaded;

  void loadProfile() {
    _isProfileLoaded = true;
    notifyListeners();
  }

  void resetProfile() {
    _isProfileLoaded = false;
    notifyListeners();
  }
}