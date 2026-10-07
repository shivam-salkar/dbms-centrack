import 'package:flutter/material.dart';
import '../models/officer.dart';
import '../models/household.dart';
import '../services/supabase_service.dart';

class AppState extends ChangeNotifier {
  bool _isDarkMode = false;
  Officer? _currentOfficer;
  int _activeDrawerIndex = 0;
  bool _isLoading = false;

  Map<String, dynamic> _dashboardStats = {
    'totalHouseholds': '0',
    'totalPersons': '0',
    'districtsCovered': '4 / 4',
    'overallCompletion': '100%',
    'overallCompletionValue': 1.0,
  };
  List<Household> _households = [];

  bool get isDarkMode => _isDarkMode;
  Officer? get currentOfficer => _currentOfficer;
  int get activeDrawerIndex => _activeDrawerIndex;
  bool get isLoading => _isLoading;
  Map<String, dynamic> get dashboardStats => _dashboardStats;
  List<Household> get households => _households;

  /// Check if Supabase session is active and restore officer profile
  Future<void> checkExistingSession() async {
    _isLoading = true;
    notifyListeners();
    try {
      final officer = await SupabaseService.getCurrentOfficer();
      if (officer != null) {
        _currentOfficer = officer;
        await refreshDashboardData();
      }
    } catch (e) {
      debugPrint('[AppState] checkExistingSession error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh households and counts from live Supabase
  Future<void> refreshDashboardData() async {
    try {
      final stats = await SupabaseService.getDashboardStats();
      final hhList = await SupabaseService.getAllHouseholds(limit: 25, offset: 0);
      _dashboardStats = stats;
      _households = hhList;
      notifyListeners();
    } catch (e) {
      debugPrint('[AppState] refreshDashboardData error: $e');
    }
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void login(Officer officer) {
    _currentOfficer = officer;
    refreshDashboardData();
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
