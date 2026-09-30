import 'package:flutter/material.dart';
import '../models/officer.dart';
import '../services/supabase_service.dart';

class AppState extends ChangeNotifier {
  bool _isDarkMode = false;
  Officer? _currentOfficer;
  int _activeDrawerIndex = 0;

  bool get isDarkMode => _isDarkMode;
  Officer? get currentOfficer => _currentOfficer;
  int get activeDrawerIndex => _activeDrawerIndex;

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void login(Officer officer) {
    _currentOfficer = officer;
    notifyListeners();
  }

  void logout() {
    SupabaseService.signOut();
    _currentOfficer = null;
    _activeDrawerIndex = 0;
    notifyListeners();
  }

  void setActiveDrawerIndex(int index) {
    _activeDrawerIndex = index;
    notifyListeners();
  }
}
