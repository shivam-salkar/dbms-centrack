import '../models/officer.dart';
import '../models/household.dart';
import '../models/person.dart';

class MockData {
  // ─── Officers ────────────────────────────────────────────────────────────────
  static const List<Officer> officers = [
    Officer(
      name: 'Rajesh Kumar Singh',
      id: 'OFF-2024-0142',
      role: 'District Administrator',
      district: 'Lucknow, Uttar Pradesh',
      email: 'rajesh.singh@census.gov.in',
      password: 'admin123',
    ),
    Officer(
      name: 'Priya Nair',
      id: 'OFF-2024-0089',
      role: 'Enumerator',
      district: 'Ernakulam, Kerala',
      email: 'priya.nair@census.gov.in',
      password: 'enum123',
    ),
  ];

  // ─── States & Districts ───────────────────────────────────────────────────────
  static const Map<String, List<String>> statesDistricts = {
    'Uttar Pradesh': ['Lucknow', 'Kanpur', 'Varanasi', 'Agra', 'Prayagraj'],
    'Maharashtra': ['Mumbai', 'Pune', 'Nagpur', 'Nashik', 'Aurangabad'],
    'Kerala': ['Ernakulam', 'Thiruvananthapuram', 'Kozhikode'],
    'Tamil Nadu': ['Chennai', 'Coimbatore', 'Madurai'],
    'Rajasthan': ['Jaipur', 'Jodhpur', 'Udaipur'],
  };

  static List<String> get states => statesDistricts.keys.toList();

  static List<String> districtsForState(String state) =>
      statesDistricts[state] ?? [];

  // ─── National Stats ───────────────────────────────────────────────────────────
  static const String totalHouseholds = '2,84,73,541';
  static const String totalPersons = '14,21,04,302';
  static const String districtsCovered = '312 / 766';
  static const String overallCompletion = '47.3%';
  static const double overallCompletionValue = 0.473;
  static const String lastUpdated = 'Today, 09:14 AM';

  // ─── District Progress ────────────────────────────────────────────────────────
  static const List<DistrictProgress> districtProgress = [
    DistrictProgress(
      district: 'Lucknow',
      state: 'Uttar Pradesh',
      tracked: 124300,
      total: 210000,
      progress: 59.2,
      lastUpdated: '2h ago',
    ),
    DistrictProgress(
      district: 'Mumbai',
      state: 'Maharashtra',
      tracked: 310000,
      total: 540000,
      progress: 57.4,
      lastUpdated: '4h ago',
    ),
    DistrictProgress(
      district: 'Ernakulam',
      state: 'Kerala',
      tracked: 87400,
      total: 110000,
      progress: 79.5,
      lastUpdated: '1h ago',
    ),
    DistrictProgress(
      district: 'Jaipur',
      state: 'Rajasthan',
      tracked: 95200,
      total: 200000,
      progress: 47.6,
      lastUpdated: '6h ago',
    ),
    DistrictProgress(
      district: 'Chennai',
      state: 'Tamil Nadu',
      tracked: 145000,
      total: 280000,
      progress: 51.8,
      lastUpdated: '3h ago',
    ),
    DistrictProgress(
      district: 'Varanasi',
      state: 'Uttar Pradesh',
      tracked: 62100,
      total: 175000,
      progress: 35.5,
      lastUpdated: '8h ago',
    ),
    DistrictProgress(
      district: 'Pune',
      state: 'Maharashtra',
      tracked: 220000,
      total: 350000,
      progress: 62.9,
      lastUpdated: '5h ago',
    ),
  ];

  // ─── Sample Households ────────────────────────────────────────────────────────
  static const List<Household> households = [
    Household(
      id: 'HH-001',
      headName: 'Ramesh Gupta',
      memberCount: 4,
      address: '12 Rajpur Road, Lucknow',
      phase1Complete: true,
      phase2Complete: true,
    ),
    Household(
      id: 'HH-002',
      headName: 'Meena Krishnan',
      memberCount: 3,
      address: '7 Marine Drive, Mumbai',
      phase1Complete: true,
      phase2Complete: false,
    ),
    Household(
      id: 'HH-003',
      headName: 'Abdul Rehman',
      memberCount: 6,
      address: '45 Gandhi Nagar, Jaipur',
      phase1Complete: false,
      phase2Complete: false,
    ),
    Household(
      id: 'HH-004',
      headName: 'Sunita Devi',
      memberCount: 2,
      address: '3 MG Road, Ernakulam',
      phase1Complete: true,
      phase2Complete: true,
    ),
    Household(
      id: 'HH-005',
      headName: 'Vikram Patel',
      memberCount: 5,
      address: '88 FC Road, Pune',
      phase1Complete: true,
      phase2Complete: false,
    ),
  ];

  // Phase 1 completed households (for Phase 2 selector)
  static List<Household> get phase1CompletedHouseholds =>
      households.where((h) => h.phase1Complete).toList();

  // ─── Sample Persons ───────────────────────────────────────────────────────────
  static const List<Person> persons = [
    Person(
      id: 'Person-001',
      name: 'Ramesh Gupta',
      sex: 'Male',
      age: 45,
      maritalStatus: 'Currently Married',
      languages: ['Hindi', 'English'],
      education: 'Graduate',
      occupation: 'Agriculture',
      householdId: 'HH-001',
    ),
    Person(
      id: 'Person-002',
      name: 'Sunita Gupta',
      sex: 'Female',
      age: 40,
      maritalStatus: 'Currently Married',
      languages: ['Hindi'],
      education: 'Secondary',
      occupation: 'Other Services',
      householdId: 'HH-001',
    ),
    Person(
      id: 'Person-003',
      name: 'Arjun Gupta',
      sex: 'Male',
      age: 19,
      maritalStatus: 'Never Married',
      languages: ['Hindi', 'English'],
      education: 'Higher Secondary',
      occupation: 'Other Services',
      householdId: 'HH-001',
    ),
    Person(
      id: 'Person-004',
      name: 'Meena Krishnan',
      sex: 'Female',
      age: 38,
      maritalStatus: 'Currently Married',
      languages: ['Malayalam', 'English'],
      education: 'Post-Graduate',
      occupation: 'Other Services',
      householdId: 'HH-002',
    ),
  ];

  // ─── Activity Feed ────────────────────────────────────────────────────────────
  static const List<Map<String, String>> recentActivity = [
    {
      'text': 'HH-001 Phase 2 submitted — Lucknow',
      'time': '09:02 AM',
      'icon': 'check_circle',
    },
    {
      'text': 'HH-004 Phase 1 verified — Ernakulam',
      'time': '08:47 AM',
      'icon': 'verified',
    },
    {
      'text': 'New enumerator assigned — Varanasi',
      'time': '08:30 AM',
      'icon': 'person_add',
    },
    {
      'text': 'HH-002 Phase 2 pending — Mumbai',
      'time': '08:15 AM',
      'icon': 'pending',
    },
    {
      'text': 'District report generated — Pune',
      'time': '07:55 AM',
      'icon': 'description',
    },
  ];

  // ─── Metrics Data ─────────────────────────────────────────────────────────────

  // State Population (in Crores)
  static const List<Map<String, dynamic>> statePopulation = [
    {'state': 'Uttar Pradesh', 'population': 24.1, 'households': '5.2 Cr', 'completion': 47.3},
    {'state': 'Maharashtra', 'population': 12.4, 'households': '2.9 Cr', 'completion': 61.2},
    {'state': 'Kerala', 'population': 3.5, 'households': '0.8 Cr', 'completion': 79.5},
    {'state': 'Tamil Nadu', 'population': 7.8, 'households': '1.9 Cr', 'completion': 51.8},
    {'state': 'Rajasthan', 'population': 8.1, 'households': '1.7 Cr', 'completion': 43.2},
  ];

  // Age Distribution
  static const List<Map<String, dynamic>> ageDistribution = [
    {'label': '0–14', 'value': 26.5},
    {'label': '15–29', 'value': 27.3},
    {'label': '30–44', 'value': 21.4},
    {'label': '45–59', 'value': 14.8},
    {'label': '60+', 'value': 10.0},
  ];

  // Literacy Rate by District (sorted descending)
  static const List<Map<String, dynamic>> literacyByDistrict = [
    {'district': 'Ernakulam', 'rate': 98.2},
    {'district': 'Mumbai', 'rate': 92.1},
    {'district': 'Chennai', 'rate': 89.4},
    {'district': 'Lucknow', 'rate': 78.3},
    {'district': 'Varanasi', 'rate': 74.1},
    {'district': 'Jaipur', 'rate': 72.4},
    {'district': 'Jodhpur', 'rate': 68.9},
  ];

  // Sex Ratio (females per 1000 males)
  static const List<Map<String, dynamic>> sexRatio = [
    {'state': 'Kerala', 'ratio': 1084},
    {'state': 'Tamil Nadu', 'ratio': 996},
    {'state': 'Maharashtra', 'ratio': 929},
    {'state': 'Rajasthan', 'ratio': 928},
    {'state': 'Uttar Pradesh', 'ratio': 912},
  ];

  // Occupation Breakdown
  static const List<Map<String, dynamic>> occupationBreakdown = [
    {'category': 'Agriculture', 'percentage': 42.0, 'persons': '5.97 Cr'},
    {'category': 'Service Sector', 'percentage': 28.0, 'persons': '3.98 Cr'},
    {'category': 'Industry', 'percentage': 18.0, 'persons': '2.56 Cr'},
    {'category': 'Unemployed', 'percentage': 12.0, 'persons': '1.71 Cr'},
  ];

  // ─── Dropdown Options ─────────────────────────────────────────────────────────

  static const List<String> predominantUse = [
    'Residential', 'Commercial', 'Mixed', 'Other'
  ];

  static const List<String> structureCondition = [
    'Good', 'Livable', 'Dilapidated'
  ];

  static const List<String> floorMaterials = [
    'Mud/Unburnt Brick', 'Wood', 'Burnt Brick', 'Stone', 'Cement',
    'Mosaic/Tiles', 'Other'
  ];

  static const List<String> wallMaterials = [
    'Grass/Thatch/Bamboo', 'Plastic', 'Mud', 'Wood', 'Unburnt Brick',
    'Burnt Brick', 'Stone', 'GI/Metal', 'Concrete', 'Other'
  ];

  static const List<String> roofMaterials = [
    'Grass/Thatch/Bamboo', 'Plastic', 'Mud', 'Wood', 'Burnt Brick',
    'Stone/Slate', 'GI/Metal', 'Concrete/Brick', 'Other'
  ];

  static const List<String> ownershipStatus = [
    'Owned', 'Rented', 'Employer Provided', 'Others'
  ];

  static const List<String> drinkingWaterSource = [
    'Tap (Treated)', 'Tap (Untreated)', 'Covered Well', 'Uncovered Well',
    'Handpump', 'River/Canal', 'Tank/Pond', 'Other'
  ];

  static const List<String> latrineFacility = [
    'Flush/Pour flush', 'Pit', 'Night soil', 'No latrine'
  ];

  static const List<String> wasteWaterOutlet = [
    'Closed drain', 'Open drain', 'No drain'
  ];

  static const List<String> cookingFuel = [
    'Firewood', 'Crop residue', 'Cow dung', 'Coal', 'Kerosene',
    'LPG', 'Electricity', 'Biogas', 'No cooking', 'Other'
  ];

  static const List<String> lightingSource = [
    'Electricity', 'Kerosene', 'Solar', 'Other', 'No light'
  ];

  static const List<String> vehicleOptions = [
    'None', 'Bicycle', 'Scooter/Motorcycle', 'Car/Jeep/Van'
  ];

  // Phase 2 dropdowns
  static const List<String> relationshipToHead = [
    'Self', 'Spouse', 'Son', 'Daughter', 'Father', 'Mother', 'Other'
  ];

  static const List<String> maritalStatus = [
    'Never Married', 'Currently Married', 'Widowed', 'Divorced', 'Separated'
  ];

  static const List<String> religions = [
    'Hindu', 'Muslim', 'Christian', 'Sikh', 'Buddhist', 'Jain',
    'Other', 'No Religion'
  ];

  static const List<String> educationLevels = [
    'No schooling', 'Below Primary', 'Primary', 'Middle', 'Secondary',
    'Higher Secondary', 'Graduate', 'Post-Graduate', 'Other'
  ];

  static const List<String> indianLanguages = [
    'Hindi', 'Bengali', 'Telugu', 'Marathi', 'Tamil', 'Urdu',
    'Gujarati', 'Kannada', 'Malayalam', 'Odia', 'Punjabi', 'Other'
  ];

  static const List<String> disabilityTypes = [
    'None', 'Visual', 'Hearing', 'Speech', 'Locomotor', 'Mental', 'Multiple'
  ];

  static const List<String> disabilityCauses = [
    'Congenital', 'Disease', 'Accident/Injury', 'Other'
  ];

  static const List<String> workerCategories = [
    'Main Worker', 'Marginal Worker'
  ];

  static const List<String> occupations = [
    'Agriculture', 'Industry', 'Trade/Commerce', 'Other Services'
  ];

  static const List<String> nonWorkingActivities = [
    'Student', 'Household duties', 'Rentier', 'Pensioner', 'Dependent', 'Other'
  ];

  static const List<String> migrationReasons = [
    'Work', 'Education', 'Marriage', 'Moved with family', 'Natural disaster', 'Other'
  ];
}
