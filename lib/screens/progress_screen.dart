import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../data/mock_data.dart';
import '../models/household.dart';
import '../theme/app_theme.dart';
import '../widgets/nav_drawer.dart';
import 'dashboard_screen.dart';
import 'phase1_entry_screen.dart';
import 'phase2_entry_screen.dart';
import 'metrics_screen.dart';
import 'login_screen.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  String? _filterState;
  int _sortColumn = 4; // progress
  bool _sortAscending = false;
  List<DistrictProgress> _filtered = List.from(MockData.districtProgress);

  void _applyFilter() {
    setState(() {
      _filtered = _filterState == null || _filterState!.isEmpty
          ? List.from(MockData.districtProgress)
          : MockData.districtProgress.where((d) => d.state == _filterState).toList();
      _sortData();
    });
  }

  void _sortData() {
    _filtered.sort((a, b) {
      int cmp;
      switch (_sortColumn) {
        case 0: cmp = a.district.compareTo(b.district); break;
        case 1: cmp = a.state.compareTo(b.state); break;
        case 4: cmp = a.progress.compareTo(b.progress); break;
        case 5: cmp = a.lastUpdated.compareTo(b.lastUpdated); break;
        default: cmp = a.progress.compareTo(b.progress);
      }
      return _sortAscending ? cmp : -cmp;
    });
  }

  void _onSort(int col) {
    setState(() {
      if (_sortColumn == col) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = col;
        _sortAscending = false;
      }
      _sortData();
    });
  }

  void _showDistrictDetail(BuildContext context, DistrictProgress d) {
    final isDark = context.read<AppState>().isDarkMode;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    d.district,
                    style: GoogleFonts.notoSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _progressColor(d.progress, isDark),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${d.progress}%',
                    style: GoogleFonts.notoSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _progressTextColor(d.progress),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(d.state, style: GoogleFonts.notoSans(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: d.progress / 100,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 16),
            _detailRow('Tracked Households', _formatNum(d.tracked), isDark),
            _detailRow('Total Households', _formatNum(d.total), isDark),
            _detailRow('Remaining', _formatNum(d.total - d.tracked), isDark),
            _detailRow('Last Updated', d.lastUpdated, isDark),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close', style: GoogleFonts.notoSans()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.notoSans(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.notoSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNum(int n) {
    if (n >= 100000) return '${(n / 100000).toStringAsFixed(1)} L';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return '$n';
  }

  Color _progressColor(double p, bool isDark) {
    if (p > 75) return isDark ? AppColors.progressHighDark : AppColors.progressHigh;
    if (p >= 50) return isDark ? AppColors.progressMidDark : AppColors.progressMid;
    return isDark ? AppColors.progressLowDark : AppColors.progressLow;
  }

  Color _progressTextColor(double p) {
    if (p > 75) return AppColors.success;
    if (p >= 50) return const Color(0xFF8B6914);
    return AppColors.error;
  }

  void _navigate(BuildContext context, int index) {
    Navigator.pop(context);
    context.read<AppState>().setActiveDrawerIndex(index);
    if (index == 0) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const DashboardScreen()), (_) => false);
    } else if (index == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const Phase1EntryScreen()));
    } else if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const Phase2EntryScreen()));
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
      appBar: AppBar(title: const Text('Progress Tracker')),
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
                  // Filter Bar
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _filterState,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            isDense: true,
                            labelText: 'Filter by State',
                          ),
                          items: [
                            DropdownMenuItem(
                              value: null,
                              child: Text('All States', style: GoogleFonts.notoSans(fontSize: 13, color: textColor)),
                            ),
                            ...MockData.states.map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s, style: GoogleFonts.notoSans(fontSize: 13, color: textColor)),
                            )),
                          ],
                          onChanged: (v) => setState(() => _filterState = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _applyFilter,
                        icon: const Icon(Icons.filter_list, size: 16),
                        label: Text('Filter', style: GoogleFonts.notoSans(fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Circular Progress Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Overall Progress',
                                      style: GoogleFonts.notoSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '312 of 766 Districts Active',
                                      style: GoogleFonts.notoSans(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 80,
                                height: 80,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      value: 0.473,
                                      strokeWidth: 8,
                                      backgroundColor: AppColors.divider,
                                      color: AppColors.primary,
                                    ),
                                    Text(
                                      '47.3%',
                                      style: GoogleFonts.notoSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _progressBar('Phase 1', 0.612, '61.2%', textColor),
                          const SizedBox(height: 12),
                          _progressBar('Phase 2', 0.387, '38.7%', textColor),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Sort header
                  Row(
                    children: [
                      Text(
                        'District Progress',
                        style: GoogleFonts.notoSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Tap column to sort',
                        style: GoogleFonts.notoSans(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Table header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    color: AppColors.primary,
                    child: Row(
                      children: [
                        _tableHeader('District', 0, flex: 2),
                        _tableHeader('State', 1, flex: 2),
                        _tableHeader('Progress', 4, flex: 3),
                        _tableHeader('Updated', 5, flex: 1),
                      ],
                    ),
                  ),

                  // Table rows
                  ..._filtered.map((d) => _buildTableRow(d, isDark, textColor)),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Export button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.background,
              border: Border(
                top: BorderSide(color: isDark ? const Color(0xFF444444) : AppColors.divider),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Report downloaded as PDF', style: GoogleFonts.notoSans()),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.download, size: 18),
                label: Text('Export Progress Report', style: GoogleFonts.notoSans(fontSize: 14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressBar(String label, double value, String text, Color textColor) {
    return Column(
      children: [
        Row(
          children: [
            Text(label, style: GoogleFonts.notoSans(fontSize: 13, color: textColor)),
            const Spacer(),
            Text(text, style: GoogleFonts.notoSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: value,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _tableHeader(String label, int col, {int flex = 1}) {
    final isActive = _sortColumn == col;
    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: () => _onSort(col),
        child: Row(
          children: [
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.notoSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isActive)
              Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 12,
                color: Colors.white,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableRow(DistrictProgress d, bool isDark, Color textColor) {
    return InkWell(
      onTap: () => _showDistrictDetail(context, d),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _progressColor(d.progress, isDark),
          border: Border(
            bottom: BorderSide(
              color: isDark ? const Color(0xFF333333) : AppColors.divider,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                d.district,
                style: GoogleFonts.notoSans(fontSize: 12, fontWeight: FontWeight.w500, color: textColor),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                d.state,
                style: GoogleFonts.notoSans(fontSize: 11, color: AppColors.textSecondary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: d.progress / 100,
                    minHeight: 5,
                    borderRadius: BorderRadius.circular(2),
                    color: _progressTextColor(d.progress),
                    backgroundColor: AppColors.divider,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${d.progress}%',
                    style: GoogleFonts.notoSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _progressTextColor(d.progress),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                d.lastUpdated,
                style: GoogleFonts.notoSans(fontSize: 10, color: AppColors.textSecondary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
