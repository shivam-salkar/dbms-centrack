import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../widgets/nav_drawer.dart';
import 'dashboard_screen.dart';
import 'phase1_entry_screen.dart';
import 'progress_screen.dart';
import 'metrics_screen.dart';
import 'login_screen.dart';

class Phase2EntryScreen extends StatefulWidget {
  const Phase2EntryScreen({super.key});

  @override
  State<Phase2EntryScreen> createState() => _Phase2EntryScreenState();
}

class _Phase2EntryScreenState extends State<Phase2EntryScreen> {
  String? _selectedHouseholdId;
  int _currentMemberIndex = 0;
  final List<Map<String, dynamic>> _members = [{}];

  Map<String, dynamic> get _current => _members[_currentMemberIndex];

  void set(String key, dynamic value) {
    setState(() => _current[key] = value);
  }

  bool get _showFertility {
    return _current['sex'] == 'Female' &&
        _current['maritalStatus'] == 'Currently Married';
  }

  bool get _showDisabilityCause {
    final d = _current['disability'] as String?;
    return d != null && d != 'None';
  }

  bool get _showWorkerCategory {
    return _current['workStatus'] == 'Worked';
  }

  bool get _showNonWorkingActivity {
    return _current['workStatus'] == 'Did not work';
  }

  bool get _showMigrationReason {
    final plr = _current['placeLastResidence'] as String?;
    return plr != null && plr != 'Same';
  }

  void _addMember() {
    setState(() {
      _members.add({});
      _currentMemberIndex = _members.length - 1;
    });
  }

  void _handleSubmit() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              'Household ${_selectedHouseholdId ?? 'HH-001'} fully enumerated',
              style: GoogleFonts.notoSans(),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _navigate(BuildContext context, int index) {
    Navigator.pop(context);
    context.read<AppState>().setActiveDrawerIndex(index);
    if (index == 0) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const DashboardScreen()), (_) => false);
    } else if (index == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const Phase1EntryScreen()));
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
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = appState.isDarkMode;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

    return Scaffold(
      appBar: AppBar(title: const Text('Phase 2 — Population Enumeration')),
      drawer: NavDrawer(
        activeIndex: appState.activeDrawerIndex,
        onNavigate: (i) => _navigate(context, i),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HH ID Selector
                  Text(
                    'Select Household',
                    style: GoogleFonts.notoSans(fontSize: 13, fontWeight: FontWeight.w500, color: textColor),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedHouseholdId,
                    isExpanded: true,
                    decoration: const InputDecoration(isDense: true),
                    hint: Text('Select Phase 1 completed household', style: GoogleFonts.notoSans(fontSize: 13)),
                    style: GoogleFonts.notoSans(fontSize: 13, color: textColor),
                    items: MockData.phase1CompletedHouseholds.map((h) => DropdownMenuItem(
                      value: h.id,
                      child: Text('${h.id} — ${h.headName}', style: GoogleFonts.notoSans(fontSize: 13, color: textColor)),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedHouseholdId = v),
                  ),
                  const SizedBox(height: 16),

                  // Member chips
                  Text('Members', style: GoogleFonts.notoSans(fontSize: 13, fontWeight: FontWeight.w500, color: textColor)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._members.asMap().entries.map((e) {
                        final name = e.value['name'] as String?;
                        return ChoiceChip(
                          label: Text(
                            name?.isNotEmpty == true ? name! : 'Member ${e.key + 1}',
                            style: GoogleFonts.notoSans(
                              fontSize: 12,
                              color: _currentMemberIndex == e.key ? Colors.white : textColor,
                            ),
                          ),
                          selected: _currentMemberIndex == e.key,
                          selectedColor: AppColors.primary,
                          backgroundColor: isDark ? const Color(0xFF2A2A2A) : AppColors.surface,
                          onSelected: (_) => setState(() => _currentMemberIndex = e.key),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(4)),
                          ),
                        );
                      }),
                      ActionChip(
                        label: Text('+ Add Member', style: GoogleFonts.notoSans(fontSize: 12, color: AppColors.primary)),
                        backgroundColor: isDark ? const Color(0xFF2A2A2A) : AppColors.surface,
                        side: const BorderSide(color: AppColors.primary),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                        ),
                        onPressed: _addMember,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Container(height: 1, color: AppColors.divider),
                  const SizedBox(height: 16),

                  // ── Section A ──
                  _buildSection(
                    title: 'A — Personal Particulars',
                    isDark: isDark,
                    children: [
                      _buildTextField('Name', 'name', maxLength: 60, textColor: textColor),
                      _buildDropdownField('Relationship to Head', 'relationship', MockData.relationshipToHead, textColor),
                      _buildRadioGroup('Sex', 'sex', const ['Male', 'Female', 'Other'], textColor),
                      _buildDatePicker('Date of Birth', 'dob', textColor, isDark),
                      _buildAgeField(textColor),
                      _buildDropdownField('Marital Status', 'maritalStatus', MockData.maritalStatus, textColor),
                      _buildDropdownField('Religion', 'religion', MockData.religions, textColor),
                    ],
                  ),

                  // ── Section B ──
                  _buildSection(
                    title: 'B — Education',
                    isDark: isDark,
                    children: [
                      _buildRadioGroup('Literacy Status', 'literacy', const ['Literate', 'Illiterate'], textColor),
                      _buildDropdownField('Education Level', 'educationLevel', MockData.educationLevels, textColor),
                      _buildRadioGroup('Current Attendance', 'attendance', const ['Never attended', 'Currently attending', 'Attended but dropped out'], textColor),
                    ],
                  ),

                  // ── Section C ──
                  _buildSection(
                    title: 'C — Languages',
                    isDark: isDark,
                    children: [
                      _buildDropdownField('Mother Tongue', 'motherTongue', MockData.indianLanguages, textColor),
                      _buildMultiSelectChips('Other Languages Known', 'otherLanguages', MockData.indianLanguages, textColor, isDark),
                    ],
                  ),

                  // ── Section D ──
                  _buildSection(
                    title: 'D — Disability',
                    isDark: isDark,
                    children: [
                      _buildRadioGroup('Disability Status', 'disability', MockData.disabilityTypes, textColor),
                      if (_showDisabilityCause)
                        _buildDropdownField('Cause of Disability', 'disabilityCause', MockData.disabilityCauses, textColor),
                    ],
                  ),

                  // ── Section E ──
                  _buildSection(
                    title: 'E — Economic Activity',
                    isDark: isDark,
                    children: [
                      _buildRadioGroup('Work Status (last year)', 'workStatus', const ['Worked', 'Did not work'], textColor),
                      if (_showWorkerCategory)
                        _buildDropdownField('Category of Worker', 'workerCategory', MockData.workerCategories, textColor),
                      if (_showWorkerCategory)
                        _buildDropdownField('Occupation', 'occupation', MockData.occupations, textColor),
                      if (_showNonWorkingActivity)
                        _buildDropdownField('Non-Working Activity', 'nonWorkingActivity', MockData.nonWorkingActivities, textColor),
                    ],
                  ),

                  // ── Section F ──
                  _buildSection(
                    title: 'F — Migration',
                    isDark: isDark,
                    children: [
                      _buildRadioGroup('Place of Birth', 'placeOfBirth', const ['Same village/town', 'Elsewhere'], textColor),
                      _buildRadioGroup('Place of Last Residence', 'placeLastResidence', const ['Same', 'Different district', 'Different state', 'Outside India'], textColor),
                      if (_showMigrationReason)
                        _buildDropdownField('Reason for Migration', 'migrationReason', MockData.migrationReasons, textColor),
                    ],
                  ),

                  // ── Section G (conditional) ──
                  if (_showFertility)
                    _buildSection(
                      title: 'G — Fertility',
                      isDark: isDark,
                      children: [
                        _buildStepperField('Children Born Alive (total)', 'childrenBorn', textColor),
                        _buildStepperField('Children Surviving (male)', 'childrenMale', textColor),
                        _buildStepperField('Children Surviving (female)', 'childrenFemale', textColor),
                        _buildRadioGroup('Children Born Last Year', 'childrenLastYear', const ['Yes', 'No'], textColor),
                      ],
                    ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // Sticky bottom bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.background,
              border: Border(
                top: BorderSide(color: isDark ? const Color(0xFF444444) : AppColors.divider),
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
                    onPressed: _addMember,
                    child: Text('Add Another Member', style: GoogleFonts.notoSans(fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _handleSubmit,
                    child: Text('Save & Submit', style: GoogleFonts.notoSans(fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
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

  Widget _buildTextField(String label, String key, {int? maxLength, required Color textColor}) {
    final controller = TextEditingController(text: _current[key] as String? ?? '');
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
            style: GoogleFonts.notoSans(fontSize: 13),
            decoration: const InputDecoration(isDense: true),
            onChanged: (v) => set(key, v),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(String label, String key, List<String> items, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.notoSans(fontSize: 12, color: textColor)),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            value: _current[key] as String?,
            isExpanded: true,
            decoration: const InputDecoration(isDense: true),
            hint: Text('Select', style: GoogleFonts.notoSans(fontSize: 13, color: AppColors.textSecondary)),
            style: GoogleFonts.notoSans(fontSize: 13, color: textColor),
            items: items.map((item) => DropdownMenuItem(
              value: item,
              child: Text(item, style: GoogleFonts.notoSans(fontSize: 13, color: textColor)),
            )).toList(),
            onChanged: (v) => set(key, v),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioGroup(String label, String key, List<String> options, Color textColor) {
    final value = _current[key] as String?;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.notoSans(fontSize: 12, color: textColor)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 0,
            children: options.map((opt) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Radio<String>(
                    value: opt,
                    groupValue: value,
                    onChanged: (v) => set(key, v),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                GestureDetector(
                  onTap: () => set(key, opt),
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

  Widget _buildDatePicker(String label, String key, Color textColor, bool isDark) {
    final dateStr = _current[key] as String? ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.notoSans(fontSize: 12, color: textColor)),
          const SizedBox(height: 4),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime(1990),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
                builder: (context, child) => Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: AppColors.primary,
                    ),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) {
                final formatted = DateFormat('dd/MM/yyyy').format(picked);
                set(key, formatted);
                final age = DateTime.now().year - picked.year;
                set('age', age.toString());
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.divider),
                borderRadius: BorderRadius.circular(4),
                color: isDark ? AppColors.darkSurface : Colors.white,
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    dateStr.isNotEmpty ? dateStr : 'dd/mm/yyyy',
                    style: GoogleFonts.notoSans(
                      fontSize: 13,
                      color: dateStr.isNotEmpty ? textColor : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgeField(Color textColor) {
    final age = _current['age'] as String? ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Age (auto-calculated, editable)', style: GoogleFonts.notoSans(fontSize: 12, color: textColor)),
          const SizedBox(height: 4),
          TextFormField(
            initialValue: age,
            keyboardType: TextInputType.number,
            style: GoogleFonts.notoSans(fontSize: 13),
            decoration: const InputDecoration(isDense: true, suffixText: 'years'),
            onChanged: (v) => set('age', v),
          ),
        ],
      ),
    );
  }

  Widget _buildStepperField(String label, String key, Color textColor) {
    final value = (_current[key] as int?) ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: GoogleFonts.notoSans(fontSize: 12, color: textColor)),
          ),
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            onPressed: value > 0 ? () => set(key, value - 1) : null,
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
            child: Text('$value', style: GoogleFonts.notoSans(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: () => set(key, value + 1),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiSelectChips(String label, String key, List<String> options, Color textColor, bool isDark) {
    final selected = (_current[key] as List<String>?) ?? [];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.notoSans(fontSize: 12, color: textColor)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: options.map((opt) {
              final isSelected = selected.contains(opt);
              return FilterChip(
                label: Text(
                  opt,
                  style: GoogleFonts.notoSans(fontSize: 11, color: isSelected ? Colors.white : textColor),
                ),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: isDark ? const Color(0xFF2A2A2A) : AppColors.surface,
                checkmarkColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
                onSelected: (val) {
                  setState(() {
                    final list = List<String>.from(selected);
                    if (val) {
                      list.add(opt);
                    } else {
                      list.remove(opt);
                    }
                    set(key, list);
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
