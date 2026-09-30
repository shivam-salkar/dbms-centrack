import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../data/mock_data.dart';
import '../models/household.dart';
import '../theme/app_theme.dart';
import '../widgets/nav_drawer.dart';
import '../widgets/stat_card.dart';
import 'phase1_entry_screen.dart';
import 'phase2_entry_screen.dart';
import 'progress_screen.dart';
import 'metrics_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _searchController = TextEditingController();
  Household? _searchResult;
  bool _searched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch(String query) {
    final q = query.trim().toUpperCase();
    setState(() {
      _searched = true;
      _searchResult = MockData.households.firstWhere(
        (h) => h.id.toUpperCase() == q ||
            h.headName.toUpperCase().contains(q),
        orElse: () => const Household(
          id: '', headName: '', memberCount: 0,
          address: '', phase1Complete: false, phase2Complete: false,
        ),
      );
      if (_searchResult!.id.isEmpty) _searchResult = null;
    });
  }

  void _navigate(BuildContext context, int index) {
    Navigator.pop(context); // close drawer
    context.read<AppState>().setActiveDrawerIndex(index);

    if (index == 0) return; // already on dashboard
    if (index == 6) {
      // Logout
      context.read<AppState>().logout();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
      return;
    }

    Widget screen;
    switch (index) {
      case 1: screen = const Phase1EntryScreen(); break;
      case 2: screen = const Phase2EntryScreen(); break;
      case 3: screen = const ProgressScreen(); break;
      case 4: screen = const MetricsScreen(); break;
      default: screen = const _PlaceholderScreen(title: 'Settings'); break;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = appState.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('National Dashboard'),
            Text(
              'Last updated: ${MockData.lastUpdated}',
              style: GoogleFonts.notoSans(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: Colors.white),
            onPressed: () => context.read<AppState>().toggleDarkMode(),
            tooltip: 'Toggle Dark Mode',
          ),
        ],
      ),
      drawer: NavDrawer(
        activeIndex: appState.activeDrawerIndex,
        onNavigate: (i) => _navigate(context, i),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Quick Stats Grid ──
            Text(
              'National Overview',
              style: GoogleFonts.notoSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                StatCard(
                  title: 'Total Households',
                  value: MockData.totalHouseholds,
                  icon: Icons.home,
                ),
                StatCard(
                  title: 'Total Persons',
                  value: MockData.totalPersons,
                  icon: Icons.people,
                ),
                StatCard(
                  title: 'Districts Covered',
                  value: MockData.districtsCovered,
                  icon: Icons.map,
                ),
                StatCard(
                  title: 'Completion',
                  value: MockData.overallCompletion,
                  icon: Icons.donut_large,
                  trailing: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      value: MockData.overallCompletionValue,
                      strokeWidth: 4,
                      backgroundColor: AppColors.divider,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Search ──
            Text(
              'Household Search',
              style: GoogleFonts.notoSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              style: GoogleFonts.notoSans(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search by Household ID (e.g. HH-001)',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward, size: 20),
                  onPressed: () => _handleSearch(_searchController.text),
                ),
              ),
              onSubmitted: _handleSearch,
            ),

            if (_searched) ...[
              const SizedBox(height: 12),
              if (_searchResult != null)
                _HouseholdCard(household: _searchResult!)
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_off, color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'No household found. Try "HH-001" to "HH-005".',
                        style: GoogleFonts.notoSans(fontSize: 13, color: AppColors.error),
                      ),
                    ],
                  ),
                ),
            ],

            const SizedBox(height: 24),

            // ── Recent Activity ──
            Text(
              'Recent Activity',
              style: GoogleFonts.notoSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: MockData.recentActivity.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = MockData.recentActivity[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _activityIcon(item['icon']!),
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['text']!,
                                style: GoogleFonts.notoSans(
                                  fontSize: 13,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item['time']!,
                                style: GoogleFonts.notoSans(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _activityIcon(String name) {
    switch (name) {
      case 'check_circle': return Icons.check_circle_outline;
      case 'verified': return Icons.verified_outlined;
      case 'person_add': return Icons.person_add_outlined;
      case 'pending': return Icons.pending_outlined;
      case 'description': return Icons.description_outlined;
      default: return Icons.info_outline;
    }
  }
}

class _HouseholdCard extends StatelessWidget {
  final Household household;
  const _HouseholdCard({required this.household});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    household.id,
                    style: GoogleFonts.notoSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                _PhaseBadge(label: 'Phase 1', complete: household.phase1Complete),
                const SizedBox(width: 8),
                _PhaseBadge(label: 'Phase 2', complete: household.phase2Complete),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              household.headName,
              style: GoogleFonts.notoSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.people, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${household.memberCount} members',
                  style: GoogleFonts.notoSans(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 16),
                Icon(Icons.location_on, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    household.address,
                    style: GoogleFonts.notoSans(fontSize: 13, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                ),
                child: Text('View Details', style: GoogleFonts.notoSans(fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhaseBadge extends StatelessWidget {
  final String label;
  final bool complete;
  const _PhaseBadge({required this.label, required this.complete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: complete
            ? AppColors.success.withValues(alpha: 0.12)
            : AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: complete ? AppColors.success : AppColors.error,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            complete ? Icons.check : Icons.close,
            size: 10,
            color: complete ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.notoSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: complete ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      drawer: NavDrawer(
        activeIndex: appState.activeDrawerIndex,
        onNavigate: (i) {
          Navigator.pop(context);
        },
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.settings, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              '$title — Coming Soon',
              style: GoogleFonts.notoSans(fontSize: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
