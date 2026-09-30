import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../widgets/nav_drawer.dart';
import 'dashboard_screen.dart';
import 'phase2_entry_screen.dart';
import 'progress_screen.dart';
import 'metrics_screen.dart';
import 'login_screen.dart';

class Phase1EntryScreen extends StatefulWidget {
  const Phase1EntryScreen({super.key});

  @override
  State<Phase1EntryScreen> createState() => _Phase1EntryScreenState();
}

class _Phase1EntryScreenState extends State<Phase1EntryScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _submitted = false;

  // Section A
  String? _state;
  String? _district;
  final _townController = TextEditingController();
  final _buildingNumberController = TextEditingController();
  final _censusHouseController = TextEditingController();
  String? _predominantUse;
  String? _structureCondition;
  int _dwellingUnits = 1;

  // Section B
  String? _floorMaterial;
  String? _wallMaterial;
  String? _roofMaterial;
  int _numRooms = 1;
  int _numCouples = 0;
  String _residenceStatus = 'Permanent';

  // Section C
  final _headNameController = TextEditingController();
  String _headSex = 'Male';
  String? _ownershipStatus;
  String? _drinkingWaterSource;
  String _waterLocation = 'Within premises';
  String? _latrineFacility;
  String? _wasteWaterOutlet;
  String _bathingFacility = 'Yes, within premises';
  String _hasKitchen = 'Yes';
  String? _cookingFuel;
  String? _lightingSource;
  int _householdSize = 1;

  // Section D
  bool _hasRadio = false;
  bool _hasTv = false;
  bool _hasComputer = false;
  bool _hasLandline = false;
  bool _hasMobile = true;
  bool _hasInternet = false;
  List<String> _vehicles = [];

  List<String> get _filteredDistricts =>
      _state != null ? MockData.districtsForState(_state!) : [];

  bool _isRequiredMissing(String? value) => _submitted && (value == null || value.isEmpty);

  void _handleSubmit() {
    setState(() => _submitted = true);
    if (_formKey.currentState!.validate() &&
        _state != null && _district != null && _predominantUse != null &&
        _structureCondition != null && _floorMaterial != null && _wallMaterial != null &&
        _roofMaterial != null && _ownershipStatus != null && _drinkingWaterSource != null &&
        _latrineFacility != null && _wasteWaterOutlet != null && _cookingFuel != null &&
        _lightingSource != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('HH-006 submitted successfully', style: GoogleFonts.notoSans()),
            ],
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _handleSaveDraft() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Draft saved', style: GoogleFonts.notoSans()),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _navigate(BuildContext context, int index) {
    Navigator.pop(context);
    context.read<AppState>().setActiveDrawerIndex(index);
    if (index == 0) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const DashboardScreen()), (_) => false);
    } else if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const Phase2EntryScreen()));
    } else if (index == 3) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProgressScreen()));
    } else if (index == 4) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const MetricsScreen()));
    } else if (index == 6) {
      context.read<AppState>().logout();
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    }
  }

  @override
  void dispose() {
    _townController.dispose();
    _buildingNumberController.dispose();
    _censusHouseController.dispose();
    _headNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = appState.isDarkMode;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

    return Scaffold(
      appBar: AppBar(title: const Text('Phase 1 — Houselisting & Housing')),
      drawer: NavDrawer(
        activeIndex: appState.activeDrawerIndex,
        onNavigate: (i) => _navigate(context, i),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HH ID chip
                    Row(
                      children: [
                        Text(
                          'Household ID:',
                          style: GoogleFonts.notoSans(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(
                            'HH-006',
                            style: GoogleFonts.notoSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          visualDensity: VisualDensity.compact,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(4)),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Auto-generated',
                          style: GoogleFonts.notoSans(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Section A ──
                    _buildExpansionTile(
                      title: 'A — Building & Identification',
                      isDark: isDark,
                      children: [
                        _buildDropdown(
                          label: 'State',
                          value: _state,
                          items: MockData.states,
                          isError: _isRequiredMissing(_state),
                          onChanged: (v) => setState(() {
                            _state = v;
                            _district = null;
                          }),
                          textColor: textColor,
                        ),
                        _buildDropdown(
                          label: 'District',
                          value: _district,
                          items: _filteredDistricts,
                          isError: _isRequiredMissing(_district),
                          onChanged: (v) => setState(() => _district = v),
                          textColor: textColor,
                          hint: _state == null ? 'Select state first' : 'Select district',
                        ),
                        _buildTextField(
                          controller: _townController,
                          label: 'Village / Town',
                          textColor: textColor,
                        ),
                        _buildTextField(
                          controller: _buildingNumberController,
                          label: 'Building Number',
                          keyboardType: TextInputType.number,
                          textColor: textColor,
                        ),
                        _buildTextField(
                          controller: _censusHouseController,
                          label: 'Census House Number',
                          keyboardType: TextInputType.number,
                          textColor: textColor,
                        ),
                        _buildDropdown(
                          label: 'Predominant Use',
                          value: _predominantUse,
                          items: MockData.predominantUse,
                          isError: _isRequiredMissing(_predominantUse),
                          onChanged: (v) => setState(() => _predominantUse = v),
                          textColor: textColor,
                        ),
                        _buildDropdown(
                          label: 'Condition of Structure',
                          value: _structureCondition,
                          items: MockData.structureCondition,
                          isError: _isRequiredMissing(_structureCondition),
                          onChanged: (v) => setState(() => _structureCondition = v),
                          textColor: textColor,
                        ),
                        _buildStepper(
                          label: 'Number of Dwelling Units',
                          value: _dwellingUnits,
                          min: 1,
                          onChanged: (v) => setState(() => _dwellingUnits = v),
                          textColor: textColor,
                        ),
                      ],
                    ),

                    // ── Section B ──
                    _buildExpansionTile(
                      title: 'B — Construction Materials',
                      isDark: isDark,
                      children: [
                        _buildDropdown(
                          label: 'Floor Material',
                          value: _floorMaterial,
                          items: MockData.floorMaterials,
                          isError: _isRequiredMissing(_floorMaterial),
                          onChanged: (v) => setState(() => _floorMaterial = v),
                          textColor: textColor,
                        ),
                        _buildDropdown(
                          label: 'Wall Material',
                          value: _wallMaterial,
                          items: MockData.wallMaterials,
                          isError: _isRequiredMissing(_wallMaterial),
                          onChanged: (v) => setState(() => _wallMaterial = v),
                          textColor: textColor,
                        ),
                        _buildDropdown(
                          label: 'Roof Material',
                          value: _roofMaterial,
                          items: MockData.roofMaterials,
                          isError: _isRequiredMissing(_roofMaterial),
                          onChanged: (v) => setState(() => _roofMaterial = v),
                          textColor: textColor,
                        ),
                        _buildStepper(
                          label: 'Number of Rooms',
                          value: _numRooms,
                          min: 1,
                          onChanged: (v) => setState(() => _numRooms = v),
                          textColor: textColor,
                        ),
                        _buildStepper(
                          label: 'Number of Married Couples',
                          value: _numCouples,
                          min: 0,
                          onChanged: (v) => setState(() => _numCouples = v),
                          textColor: textColor,
                        ),
                        _buildRadioGroup(
                          label: 'Residence Status',
                          value: _residenceStatus,
                          options: const ['Permanent', 'Temporary', 'Homeless'],
                          onChanged: (v) => setState(() => _residenceStatus = v!),
                          textColor: textColor,
                        ),
                      ],
                    ),

                    // ── Section C ──
                    _buildExpansionTile(
                      title: 'C — Household & Amenities',
                      isDark: isDark,
                      children: [
                        _buildTextFieldWithCount(
                          controller: _headNameController,
                          label: 'Name of Head of Household',
                          maxLength: 60,
                          textColor: textColor,
                        ),
                        _buildRadioGroup(
                          label: 'Sex of Head',
                          value: _headSex,
                          options: const ['Male', 'Female', 'Other'],
                          onChanged: (v) => setState(() => _headSex = v!),
                          textColor: textColor,
                        ),
                        _buildDropdown(
                          label: 'Ownership Status',
                          value: _ownershipStatus,
                          items: MockData.ownershipStatus,
                          isError: _isRequiredMissing(_ownershipStatus),
                          onChanged: (v) => setState(() => _ownershipStatus = v),
                          textColor: textColor,
                        ),
                        _buildDropdown(
                          label: 'Source of Drinking Water',
                          value: _drinkingWaterSource,
                          items: MockData.drinkingWaterSource,
                          isError: _isRequiredMissing(_drinkingWaterSource),
                          onChanged: (v) => setState(() => _drinkingWaterSource = v),
                          textColor: textColor,
                        ),
                        _buildRadioGroup(
                          label: 'Location of Drinking Water',
                          value: _waterLocation,
                          options: const ['Within premises', 'Near premises', 'Away'],
                          onChanged: (v) => setState(() => _waterLocation = v!),
                          textColor: textColor,
                        ),
                        _buildDropdown(
                          label: 'Latrine Facility',
                          value: _latrineFacility,
                          items: MockData.latrineFacility,
                          isError: _isRequiredMissing(_latrineFacility),
                          onChanged: (v) => setState(() => _latrineFacility = v),
                          textColor: textColor,
                        ),
                        _buildDropdown(
                          label: 'Waste Water Outlet',
                          value: _wasteWaterOutlet,
                          items: MockData.wasteWaterOutlet,
                          isError: _isRequiredMissing(_wasteWaterOutlet),
                          onChanged: (v) => setState(() => _wasteWaterOutlet = v),
                          textColor: textColor,
                        ),
                        _buildRadioGroup(
                          label: 'Bathing Facility',
                          value: _bathingFacility,
                          options: const ['Yes, within premises', 'Yes, outside', 'No'],
                          onChanged: (v) => setState(() => _bathingFacility = v!),
                          textColor: textColor,
                        ),
                        _buildRadioGroup(
                          label: 'Availability of Kitchen',
                          value: _hasKitchen,
                          options: const ['Yes', 'No'],
                          onChanged: (v) => setState(() => _hasKitchen = v!),
                          textColor: textColor,
                        ),
                        _buildDropdown(
                          label: 'Fuel for Cooking',
                          value: _cookingFuel,
                          items: MockData.cookingFuel,
                          isError: _isRequiredMissing(_cookingFuel),
                          onChanged: (v) => setState(() => _cookingFuel = v),
                          textColor: textColor,
                        ),
                        _buildDropdown(
                          label: 'Lighting Source',
                          value: _lightingSource,
                          items: MockData.lightingSource,
                          isError: _isRequiredMissing(_lightingSource),
                          onChanged: (v) => setState(() => _lightingSource = v),
                          textColor: textColor,
                        ),
                        _buildStepper(
                          label: 'Household Size',
                          value: _householdSize,
                          min: 1,
                          onChanged: (v) => setState(() => _householdSize = v),
                          textColor: textColor,
                        ),
                      ],
                    ),

                    // ── Section D ──
                    _buildExpansionTile(
                      title: 'D — Assets & Connectivity',
                      isDark: isDark,
                      children: [
                        _buildToggle('Radio/Transistor', _hasRadio, (v) => setState(() => _hasRadio = v), textColor),
                        _buildToggle('Television', _hasTv, (v) => setState(() => _hasTv = v), textColor),
                        _buildToggle('Computer/Laptop', _hasComputer, (v) => setState(() => _hasComputer = v), textColor),
                        _buildToggle('Telephone (Landline)', _hasLandline, (v) => setState(() => _hasLandline = v), textColor),
                        _buildToggle('Mobile Phone', _hasMobile, (v) => setState(() => _hasMobile = v), textColor),
                        _buildToggle('Internet Access', _hasInternet, (v) => setState(() => _hasInternet = v), textColor),
                        const SizedBox(height: 8),
                        Text(
                          'Bicycle/Scooter/Car',
                          style: GoogleFonts.notoSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: MockData.vehicleOptions.map((v) {
                            final selected = _vehicles.contains(v);
                            return FilterChip(
                              label: Text(
                                v,
                                style: GoogleFonts.notoSans(
                                  fontSize: 12,
                                  color: selected ? Colors.white : textColor,
                                ),
                              ),
                              selected: selected,
                              selectedColor: AppColors.primary,
                              backgroundColor: isDark ? const Color(0xFF2A2A2A) : AppColors.surface,
                              checkmarkColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(4)),
                              ),
                              onSelected: (val) {
                                setState(() {
                                  if (v == 'None') {
                                    _vehicles = val ? ['None'] : [];
                                  } else {
                                    _vehicles.remove('None');
                                    if (val) {
                                      _vehicles.add(v);
                                    } else {
                                      _vehicles.remove(v);
                                    }
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),

            // Sticky Bottom Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.background,
                border: Border(
                  top: BorderSide(
                    color: isDark ? const Color(0xFF444444) : AppColors.divider,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _handleSaveDraft,
                      child: Text('Save Draft', style: GoogleFonts.notoSans(fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _handleSubmit,
                      child: Text('Submit Entry', style: GoogleFonts.notoSans(fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpansionTile({
    required String title,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(
          title,
          style: GoogleFonts.notoSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required Color textColor,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.notoSans(fontSize: 12, color: textColor)),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            style: GoogleFonts.notoSans(fontSize: 14),
            decoration: const InputDecoration(isDense: true),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFieldWithCount({
    required TextEditingController controller,
    required String label,
    required int maxLength,
    required Color textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.notoSans(fontSize: 12, color: textColor)),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            maxLength: maxLength,
            style: GoogleFonts.notoSans(fontSize: 14),
            decoration: const InputDecoration(isDense: true),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required Color textColor,
    bool isError = false,
    String hint = 'Select',
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: GoogleFonts.notoSans(fontSize: 12, color: textColor)),
              if (isError) ...[
                const SizedBox(width: 4),
                const Icon(Icons.error, size: 12, color: AppColors.error),
              ],
            ],
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            value: value,
            isExpanded: true,
            decoration: InputDecoration(
              isDense: true,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(
                  color: isError ? AppColors.error : AppColors.divider,
                  width: isError ? 1.5 : 1,
                ),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(4)),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            hint: Text(hint, style: GoogleFonts.notoSans(fontSize: 13, color: AppColors.textSecondary)),
            style: GoogleFonts.notoSans(fontSize: 13, color: textColor),
            items: items.map((item) => DropdownMenuItem(
              value: item,
              child: Text(item, style: GoogleFonts.notoSans(fontSize: 13, color: textColor)),
            )).toList(),
            onChanged: items.isEmpty ? null : onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildRadioGroup({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
    required Color textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.notoSans(fontSize: 12, color: textColor)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            children: options.map((opt) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Radio<String>(
                    value: opt,
                    groupValue: value,
                    onChanged: onChanged,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                GestureDetector(
                  onTap: () => onChanged(opt),
                  child: Text(opt, style: GoogleFonts.notoSans(fontSize: 12, color: textColor)),
                ),
                const SizedBox(width: 8),
              ],
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper({
    required String label,
    required int value,
    required int min,
    required ValueChanged<int> onChanged,
    required Color textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: GoogleFonts.notoSans(fontSize: 12, color: textColor)),
          ),
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            onPressed: value > min ? () => onChanged(value - 1) : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          Container(
            width: 40,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$value',
              style: GoogleFonts.notoSans(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: () => onChanged(value + 1),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(String label, bool value, ValueChanged<bool> onChanged, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: GoogleFonts.notoSans(fontSize: 13, color: textColor)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          SizedBox(
            width: 30,
            child: Text(
              value ? 'Yes' : 'No',
              style: GoogleFonts.notoSans(
                fontSize: 12,
                color: value ? AppColors.success : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
