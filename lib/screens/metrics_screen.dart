import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../widgets/nav_drawer.dart';
import 'dashboard_screen.dart';
import 'phase1_entry_screen.dart';
import 'phase2_entry_screen.dart';
import 'progress_screen.dart';
import 'login_screen.dart';

class MetricsScreen extends StatefulWidget {
  const MetricsScreen({super.key});

  @override
  State<MetricsScreen> createState() => _MetricsScreenState();
}

class _MetricsScreenState extends State<MetricsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
    } else if (index == 3) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProgressScreen()));
    } else if (index == 6) {
      context.read<AppState>().logout();
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    }
  }

  void _exportPdf() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Analytics report exported', style: GoogleFonts.notoSans()),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = appState.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Metrics & Analytics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Demographics'),
            Tab(text: 'Literacy'),
            Tab(text: 'Occupation'),
          ],
          isScrollable: false,
          indicatorWeight: 3,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.white),
            onPressed: _exportPdf,
            tooltip: 'Export as PDF',
          ),
        ],
      ),
      drawer: NavDrawer(
        activeIndex: appState.activeDrawerIndex,
        onNavigate: (i) => _navigate(context, i),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(isDark: isDark),
          _DemographicsTab(isDark: isDark),
          _LiteracyTab(isDark: isDark),
          _OccupationTab(isDark: isDark),
        ],
      ),
    );
  }
}

// ─── Tab 1: Overview ─────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final bool isDark;
  const _OverviewTab({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final data = MockData.statePopulation;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'State-wise Population (Crores)',
            style: GoogleFonts.notoSans(fontSize: 15, fontWeight: FontWeight.w600, color: textColor),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
              child: SizedBox(
                height: 220,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 30,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => AppColors.primary,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${data[groupIndex]['state']}\n${rod.toY} Cr',
                            GoogleFonts.notoSans(color: Colors.white, fontSize: 11),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx >= data.length) return const SizedBox();
                            final state = data[idx]['state'] as String;
                            final abbr = state.length > 4 ? state.substring(0, 4) : state;
                            return Text(
                              abbr,
                              style: GoogleFonts.notoSans(fontSize: 9, color: textColor),
                            );
                          },
                          reservedSize: 24,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          getTitlesWidget: (value, meta) => Text(
                            '${value.toInt()}',
                            style: GoogleFonts.notoSans(fontSize: 9, color: textColor),
                          ),
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: AppColors.divider.withValues(alpha: 0.5),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: data.asMap().entries.map((e) {
                      return BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: (e.value['population'] as num).toDouble(),
                            color: AppColors.chartColors[e.key % AppColors.chartColors.length],
                            width: 22,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
          Text(
            'Summary Table',
            style: GoogleFonts.notoSans(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _tableRow(isDark: isDark, isHeader: true, cells: ['State', 'Population', 'Households', 'Completion']),
                const Divider(height: 1),
                ...data.map((d) => Column(
                  children: [
                    _tableRow(
                      isDark: isDark,
                      cells: [
                        d['state'] as String,
                        '${d['population']} Cr',
                        d['households'] as String,
                        '${d['completion']}%',
                      ],
                    ),
                    const Divider(height: 1),
                  ],
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab 2: Demographics ──────────────────────────────────────────────────────

class _DemographicsTab extends StatelessWidget {
  final bool isDark;
  const _DemographicsTab({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final ageData = MockData.ageDistribution;
    final sexData = MockData.sexRatio;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Age Distribution',
            style: GoogleFonts.notoSans(fontSize: 15, fontWeight: FontWeight.w600, color: textColor),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sections: ageData.asMap().entries.map((e) {
                          final color = AppColors.chartColors[e.key % AppColors.chartColors.length];
                          return PieChartSectionData(
                            color: color,
                            value: (e.value['value'] as num).toDouble(),
                            title: '${e.value['value']}%',
                            radius: 80,
                            titleStyle: GoogleFonts.notoSans(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
                          );
                        }).toList(),
                        sectionsSpace: 2,
                        centerSpaceRadius: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Legend
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: ageData.asMap().entries.map((e) {
                      final color = AppColors.chartColors[e.key % AppColors.chartColors.length];
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 12, height: 12, color: color),
                          const SizedBox(width: 4),
                          Text(
                            '${e.value['label']} (${e.value['value']}%)',
                            style: GoogleFonts.notoSans(fontSize: 11, color: textColor),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          // Summary cards
          Row(
            children: [
              Expanded(child: _summaryCard('Avg Household Size', '4.9', Icons.home, isDark)),
              const SizedBox(width: 12),
              Expanded(child: _summaryCard('Child Sex Ratio', '918', Icons.child_care, isDark)),
            ],
          ),

          const SizedBox(height: 20),
          Text('Sex Ratio by State (per 1000 males)',
            style: GoogleFonts.notoSans(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _tableRow(isDark: isDark, isHeader: true, cells: ['State', 'Females/1000 Males']),
                const Divider(height: 1),
                ...sexData.map((d) => Column(
                  children: [
                    _tableRow(isDark: isDark, cells: [d['state'] as String, '${d['ratio']}']),
                    const Divider(height: 1),
                  ],
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.notoSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.notoSans(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab 3: Literacy ─────────────────────────────────────────────────────────

class _LiteracyTab extends StatelessWidget {
  final bool isDark;
  const _LiteracyTab({required this.isDark});

  static const double _nationalAvg = 77.7;

  Color _barColor(double rate) {
    if (rate >= 90) return AppColors.success;
    if (rate >= 70) return AppColors.accent;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final data = MockData.literacyByDistrict;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Literacy Rate by District (%)',
            style: GoogleFonts.notoSans(fontSize: 15, fontWeight: FontWeight.w600, color: textColor),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(width: 20, height: 2, color: AppColors.error),
              const SizedBox(width: 4),
              Text('National Avg: $_nationalAvg%', style: GoogleFonts.notoSans(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
              child: SizedBox(
                height: 260,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 110,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => AppColors.primary,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${data[groupIndex]['district']}\n${rod.toY}%',
                            GoogleFonts.notoSans(color: Colors.white, fontSize: 11),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx >= data.length) return const SizedBox();
                            final name = data[idx]['district'] as String;
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                name.length > 5 ? name.substring(0, 5) : name,
                                style: GoogleFonts.notoSans(fontSize: 9, color: textColor),
                              ),
                            );
                          },
                          reservedSize: 24,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          getTitlesWidget: (value, meta) => Text(
                            '${value.toInt()}%',
                            style: GoogleFonts.notoSans(fontSize: 9, color: textColor),
                          ),
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) {
                        if (value == _nationalAvg) {
                          return FlLine(color: AppColors.error, strokeWidth: 1.5, dashArray: [5, 3]);
                        }
                        return FlLine(
                          color: AppColors.divider.withValues(alpha: 0.5),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: data.asMap().entries.map((e) {
                      final rate = (e.value['rate'] as num).toDouble();
                      return BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: rate,
                            color: _barColor(rate),
                            width: 22,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),
          // Color legend
          Row(
            children: [
              _legendItem(AppColors.success, '≥90% (High)'),
              const SizedBox(width: 12),
              _legendItem(AppColors.accent, '70–90% (Medium)'),
              const SizedBox(width: 12),
              _legendItem(AppColors.error, '<70% (Low)'),
            ],
          ),

          const SizedBox(height: 20),
          Text(
            'District Literacy Table',
            style: GoogleFonts.notoSans(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _tableRow(isDark: isDark, isHeader: true, cells: ['District', 'Rate', 'Rank']),
                const Divider(height: 1),
                ...data.asMap().entries.map((e) {
                  final rate = (e.value['rate'] as num).toDouble();
                  return Column(
                    children: [
                      Container(
                        color: rate >= 90
                            ? AppColors.success.withValues(alpha: isDark ? 0.15 : 0.08)
                            : rate >= 70
                                ? AppColors.accent.withValues(alpha: isDark ? 0.15 : 0.08)
                                : AppColors.error.withValues(alpha: isDark ? 0.15 : 0.08),
                        child: _tableRow(
                          isDark: isDark,
                          cells: [
                            e.value['district'] as String,
                            '${e.value['rate']}%',
                            '#${e.key + 1}',
                          ],
                          rateColor: _barColor(rate),
                        ),
                      ),
                      const Divider(height: 1),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.notoSans(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }
}

// ─── Tab 4: Occupation ────────────────────────────────────────────────────────

class _OccupationTab extends StatelessWidget {
  final bool isDark;
  const _OccupationTab({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final data = MockData.occupationBreakdown;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Occupation Distribution',
            style: GoogleFonts.notoSans(fontSize: 15, fontWeight: FontWeight.w600, color: textColor),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sections: data.asMap().entries.map((e) {
                          final color = AppColors.chartColors[e.key % AppColors.chartColors.length];
                          return PieChartSectionData(
                            color: color,
                            value: (e.value['percentage'] as num).toDouble(),
                            title: '${e.value['percentage']}%',
                            radius: 80,
                            titleStyle: GoogleFonts.notoSans(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
                          );
                        }).toList(),
                        sectionsSpace: 2,
                        centerSpaceRadius: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: data.asMap().entries.map((e) {
                      final color = AppColors.chartColors[e.key % AppColors.chartColors.length];
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 12, height: 12, color: color),
                          const SizedBox(width: 4),
                          Text(
                            '${e.value['category']} (${e.value['percentage']}%)',
                            style: GoogleFonts.notoSans(fontSize: 11, color: textColor),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _infoCard('Main Workers', '42.3%', isDark)),
              const SizedBox(width: 12),
              Expanded(child: _infoCard('Marginal Workers', '8.1%', isDark)),
            ],
          ),

          const SizedBox(height: 20),
          Text(
            'Occupation Breakdown Table',
            style: GoogleFonts.notoSans(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _tableRow(isDark: isDark, isHeader: true, cells: ['Category', 'Persons', 'Percentage']),
                const Divider(height: 1),
                ...data.map((d) => Column(
                  children: [
                    _tableRow(
                      isDark: isDark,
                      cells: [
                        d['category'] as String,
                        d['persons'] as String,
                        '${d['percentage']}%',
                      ],
                    ),
                    const Divider(height: 1),
                  ],
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String title, String value, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.notoSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.notoSans(fontSize: 12, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared Helpers ───────────────────────────────────────────────────────────

Widget _tableRow({
  required bool isDark,
  required List<String> cells,
  bool isHeader = false,
  Color? rateColor,
}) {
  final textColor = isHeader
      ? Colors.white
      : isDark
          ? AppColors.darkTextPrimary
          : AppColors.textPrimary;

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    color: isHeader ? AppColors.primary : Colors.transparent,
    child: Row(
      children: cells.asMap().entries.map((e) {
        final isLast = e.key == cells.length - 1;
        Color cellColor = textColor;
        if (!isHeader && rateColor != null && e.key == 1) {
          cellColor = rateColor;
        }
        return Expanded(
          child: Text(
            e.value,
            style: GoogleFonts.notoSans(
              fontSize: isHeader ? 12 : 12,
              fontWeight: isHeader ? FontWeight.w600 : FontWeight.normal,
              color: cellColor,
            ),
            textAlign: isLast ? TextAlign.right : TextAlign.left,
          ),
        );
      }).toList(),
    ),
  );
}
