import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/officer.dart';
import '../data/mock_data.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://azmpvvbivdkqjdrqcmba.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF6bXB2dmJpdmRrcWpkcnFjbWJhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA3OTEzODUsImV4cCI6MjEwNjM2NzM4NX0.mJmbQQaLHdM53qfnGf3kza_mWTgHtdbYLk6viAgknqc';

  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  static SupabaseClient get client => Supabase.instance.client;

  /// Initialize Supabase client
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      _initialized = true;
      debugPrint('[SupabaseService] Initialized successfully');
    } catch (e) {
      debugPrint('[SupabaseService] Failed to initialize: $e');
      _initialized = false;
    }
  }

  /// Sign in with Supabase Auth
  static Future<Officer?> signIn({
    required String email,
    required String password,
  }) async {
    if (!_initialized) {
      return _fallbackMockLogin(email, password);
    }

    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        return _fallbackMockLogin(email, password);
      }

      // Try fetching enumerator profile linked to this auth user
      try {
        final profile = await client
            .from('enumerator')
            .select()
            .eq('auth_user_id', user.id)
            .maybeSingle();

        if (profile != null) {
          return Officer(
            name: profile['name'] ?? user.userMetadata?['name'] ?? 'Census Officer',
            id: profile['employee_code'] ?? 'OFF-REMOTE',
            role: profile['role'] ?? 'Enumerator',
            district: 'Central Division',
            email: email,
            password: '',
          );
        }
      } catch (profileError) {
        debugPrint('[SupabaseService] Profile query notice: $profileError');
      }

      // Return officer from auth metadata
      final meta = user.userMetadata ?? {};
      return Officer(
        name: meta['name'] ?? 'Census Officer',
        id: meta['employee_code'] ?? 'OFF-${user.id.substring(0, 8)}',
        role: meta['role'] ?? 'Enumerator',
        district: 'Central Division',
        email: email,
        password: '',
      );
    } catch (e) {
      debugPrint('[SupabaseService] Auth failed: $e, checking mock fallback');
      return _fallbackMockLogin(email, password);
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    if (_initialized) {
      try {
        await client.auth.signOut();
      } catch (e) {
        debugPrint('[SupabaseService] Sign out error: $e');
      }
    }
  }

  /// Fetch cities from Supabase
  static Future<List<Map<String, dynamic>>> getCities() async {
    if (!_initialized) return [];
    try {
      final data = await client.from('city').select();
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('[SupabaseService] Fetch cities error: $e');
      return [];
    }
  }

  /// Fetch reference data for form dropdowns
  static Future<Map<String, List<Map<String, dynamic>>>> getReferenceData() async {
    if (!_initialized) return {};
    try {
      final results = await Future.wait([
        client.from('language').select(),
        client.from('caste').select(),
        client.from('education_level').select(),
        client.from('occupation').select(),
        client.from('disability').select(),
      ]);

      return {
        'languages': List<Map<String, dynamic>>.from(results[0]),
        'castes': List<Map<String, dynamic>>.from(results[1]),
        'education_levels': List<Map<String, dynamic>>.from(results[2]),
        'occupations': List<Map<String, dynamic>>.from(results[3]),
        'disabilities': List<Map<String, dynamic>>.from(results[4]),
      };
    } catch (e) {
      debugPrint('[SupabaseService] Fetch reference data error: $e');
      return {};
    }
  }

  /// Fallback matching against mock data for offline support
  static Officer? _fallbackMockLogin(String email, String password) {
    for (final o in MockData.officers) {
      if (o.email == email && o.password == password) {
        return o;
      }
    }
    return null;
  }
}
