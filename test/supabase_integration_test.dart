import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:census_tracker/services/supabase_service.dart';

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _TestHttpOverrides();
  SharedPreferences.setMockInitialValues({});

  setUpAll(() async {
    await SupabaseService.initialize();
  });

  group('Supabase Integration & Authentication Audit Tests', () {
    test('1. Supabase initialization', () {
      expect(SupabaseService.isInitialized, isTrue);
      expect(SupabaseService.client, isNotNull);
    });

    test('2. Authentication: Valid Admin login succeeds with ADMIN role', () async {
      final officer = await SupabaseService.signIn(
        email: 'admin.demo@janganatest.local',
        password: 'JanganaDemo@2026',
      );
      expect(officer, isNotNull);
      expect(officer!.email, 'admin.demo@janganatest.local');
      expect(officer.role.toUpperCase(), 'ADMIN');
      expect(officer.isAdmin, isTrue);
      await SupabaseService.signOut();
    });

    test('3. Authentication: Valid Enumerator login succeeds', () async {
      final officer = await SupabaseService.signIn(
        email: 'enumerator1.demo@janganatest.local',
        password: 'JanganaEnum@2026',
      );
      expect(officer, isNotNull);
      expect(officer!.email, 'enumerator1.demo@janganatest.local');
      expect(officer.role.toUpperCase(), 'ENUMERATOR');
      expect(officer.isAdmin, isFalse);
      await SupabaseService.signOut();
    });

    test('4. Authentication: Invalid password is strictly rejected', () async {
      final officer = await SupabaseService.signIn(
        email: 'admin.demo@janganatest.local',
        password: 'WrongPassword_2026!',
      );
      expect(officer, isNull);
    });

    test('5. Database READ: Cities and Reference Data', () async {
      final cities = await SupabaseService.getCities();
      expect(cities, isNotEmpty);

      final ref = await SupabaseService.getReferenceData();
      expect(ref['languages'], isNotEmpty);
      expect(ref['castes'], isNotEmpty);
      expect(ref['occupations'], isNotEmpty);
    });

    test('6. Database READ: All Households from Supabase', () async {
      final households = await SupabaseService.getAllHouseholds();
      expect(households, isNotEmpty);
      expect(households.any((h) => h.id == 'HH-001'), isTrue);
    });

    test('7. End-to-End CRUD Cycle: INSERT -> READ -> UPDATE -> REVERSE UPDATE -> DELETE', () async {
      // Sign in as Enumerator 1
      final officer = await SupabaseService.signIn(
        email: 'enumerator1.demo@janganatest.local',
        password: 'JanganaEnum@2026',
      );
      expect(officer, isNotNull);

      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final testHouseholdId = 'TEST_JANGANA_INTEGRATION_$timestamp';

      // 1. INSERT through SupabaseService
      final created = await SupabaseService.createHouseholdPhase1(
        censusHouseNumber: testHouseholdId,
        buildingNumber: 'BLD-TEST-$timestamp',
        locality: 'Hazratganj Central',
        headName: 'Test Head Person',
        residentsCount: 5,
        headCategory: 'GEN',
        dwellingRooms: 3,
        floorMaterial: 'Concrete',
        wallMaterial: 'Burnt Brick',
        roofMaterial: 'R.C.C.',
        ownershipStatus: 'Owned',
      );

      expect(created, isNotNull);
      expect(created!.id, testHouseholdId);
      expect(created.memberCount, 5);

      // 2. READ: Verify record exists in Supabase
      final found = await SupabaseService.searchHouseholds(testHouseholdId);
      expect(found, isNotEmpty);
      expect(found.first.id, testHouseholdId);
      expect(found.first.memberCount, 5);

      // 3. UPDATE: 5 -> 6
      final updateSuccess = await SupabaseService.updateHouseholdResidentsCount(
        householdIdOrNumber: testHouseholdId,
        count: 6,
      );
      expect(updateSuccess, isTrue);

      final updatedFound = await SupabaseService.searchHouseholds(testHouseholdId);
      expect(updatedFound, isNotEmpty);
      expect(updatedFound.first.memberCount, 6);

      // 4. Reverse UPDATE directly in Supabase: 6 -> 7
      final reverseSuccess = await SupabaseService.updateHouseholdResidentsCount(
        householdIdOrNumber: testHouseholdId,
        count: 7,
      );
      expect(reverseSuccess, isTrue);

      // Re-fetch in Flutter and verify it reflects 7
      final revFound = await SupabaseService.searchHouseholds(testHouseholdId);
      expect(revFound, isNotEmpty);
      expect(revFound.first.memberCount, 7);

      // 5. DELETE: Remove the dedicated test record
      final deleteSuccess = await SupabaseService.deleteHousehold(testHouseholdId);
      expect(deleteSuccess, isTrue);

      // Verify it disappeared from Supabase
      final afterDelete = await SupabaseService.searchHouseholds(testHouseholdId);
      expect(afterDelete, isEmpty);

      await SupabaseService.signOut();
    });
  });
}
