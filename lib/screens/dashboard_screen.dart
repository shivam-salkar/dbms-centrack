import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../data/mock_data.dart';
import '../models/household.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';
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
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().refreshDashboardData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() {
        _searched = false;
        _searchResult = null;
      });
      return;
    }

    setState(() {
      _searched = true;
      _isSearching = true;
    });

    final results = await SupabaseService.searchHouseholds(q);

    if (!mounted) return;
    setState(() {
      _isSearching = false;
      _searchResult = results.isNotEmpty ? results.first : null;
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
      case 1:
        screen = const Phase1EntryScreen();
        break;
      case 2:
        screen = const Phase2EntryScreen();
        break;
      case 3:
        screen = const ProgressScreen();
        break;
      case 4:
        screen = const MetricsScreen();
        break;
      default:
        screen = const _PlaceholderScreen(title: 'Settings');
        break;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = appState.isDarkMode;
    final stats = appState.dashboardStats;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('National Dashboard'),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Supabase Connected • Live',
                  style: GoogleFonts.notoSans(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh from Supabase',
            onPressed: () async {
              await appState.refreshDashboardData();
              if (_searchResult != null) {
                final res = await SupabaseService.searchHouseholds(_searchResult!.id);
                if (res.isNotEmpty && mounted) {
                  setState(() => _searchResult = res.first);
                }
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Refreshed data from Supabase'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Live Census Overview (Supabase)',
                  style: GoogleFonts.notoSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${appState.households.length} Households in DB',
                  style: GoogleFonts.notoSans(
                    fontSize: 12,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
                  value: stats['totalHouseholds'] ?? '0',
                  icon: Icons.home,
                ),
                StatCard(
                  title: 'Total Persons',
                  value: stats['totalPersons'] ?? '0',
                  icon: Icons.people,
                ),
                StatCard(
                  title: 'Districts Covered',
                  value: stats['districtsCovered'] ?? '4 / 4',
                  icon: Icons.map,
                ),
                StatCard(
                  title: 'Completion Status',
                  value: stats['overallCompletion'] ?? 'Live DB',
                  icon: Icons.donut_large,
                  trailing: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      value: (stats['overallCompletionValue'] as num?)?.toDouble() ?? 1.0,
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
              'Household Search (Live Supabase)',
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
                hintText: 'Search by Household ID (e.g. HH-001, HH-002, TEST_...)',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward, size: 20),
                  onPressed: () => _handleSearch(_searchController.text),
                ),
              ),
              onSubmitted: _handleSearch,
            ),

            if (_isSearching) ...[
              const SizedBox(height: 12),
              const Center(child: CircularProgressIndicator()),
            ] else if (_searched) ...[
              const SizedBox(height: 12),
              if (_searchResult != null)
                _HouseholdCard(
                  household: _searchResult!,
                  onUpdated: (updated) {
                    setState(() => _searchResult = updated);
                  },
                  onDeleted: () {
                    setState(() => _searchResult = null);
                  },
                )
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
                      Expanded(
                        child: Text(
                          'No household matching "${_searchController.text}" found in Supabase.',
                          style: GoogleFonts.notoSans(fontSize: 13, color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
            ],

            const SizedBox(height: 24),

            // ── Live Supabase Households List ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Live Supabase Records',
                  style: GoogleFonts.notoSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => appState.refreshDashboardData(),
                  icon: const Icon(Icons.sync, size: 16),
                  label: const Text('Sync', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (appState.households.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'No census records found in database. Use "Data Entry Phase 1" to create one!',
                    style: GoogleFonts.notoSans(fontSize: 13, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: appState.households.length,
                itemBuilder: (context, index) {
                  final hh = appState.households[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: _HouseholdCard(
                      household: hh,
                      onUpdated: (_) => appState.refreshDashboardData(),
                      onDeleted: () => appState.refreshDashboardData(),
                    ),
                  );
                },
              ),

            const SizedBox(height: 24),

            // ── Recent Activity ──
            Text(
              'Activity Trail',
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
      case 'check_circle':
        return Icons.check_circle_outline;
      case 'verified':
        return Icons.verified_outlined;
      case 'person_add':
        return Icons.person_add_outlined;
      case 'pending':
        return Icons.pending_outlined;
      case 'description':
        return Icons.description_outlined;
      default:
        return Icons.info_outline;
    }
  }
}

class _HouseholdCard extends StatelessWidget {
  final Household household;
  final ValueChanged<Household>? onUpdated;
  final VoidCallback? onDeleted;

  const _HouseholdCard({
    required this.household,
    this.onUpdated,
    this.onDeleted,
  });

  Future<void> _handleEditResidents(BuildContext context) async {
    final controller = TextEditingController(text: household.memberCount.toString());
    final newCount = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Residents Count: ${household.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current residents count: ${household.memberCount}',
              style: GoogleFonts.notoSans(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'New Residents Count',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final count = int.tryParse(controller.text.trim());
              Navigator.pop(ctx, count);
            },
            child: const Text('Save to Supabase'),
          ),
        ],
      ),
    );

    if (newCount != null && context.mounted) {
      final messenger = ScaffoldMessenger.of(context);
      final appState = context.read<AppState>();
      final success = await SupabaseService.updateHouseholdResidentsCount(
        householdIdOrNumber: household.dbId ?? household.id,
        count: newCount,
      );
      if (success) {
        await appState.refreshDashboardData();
        onUpdated?.call(household.copyWith(memberCount: newCount));
        messenger.showSnackBar(
          SnackBar(
            content: Text('Updated ${household.id} residents count to $newCount in Supabase'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to update residents count in Supabase'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Household ${household.id}?'),
        content: Text(
          'Are you sure you want to delete this record (${household.headName}, ${household.memberCount} members) from Supabase?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete from Supabase'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final messenger = ScaffoldMessenger.of(context);
      final appState = context.read<AppState>();
      final success = await SupabaseService.deleteHousehold(household.dbId ?? household.id);
      if (success) {
        await appState.refreshDashboardData();
        onDeleted?.call();
        messenger.showSnackBar(
          SnackBar(
            content: Text('Deleted ${household.id} from Supabase'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to delete household from Supabase'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

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
                const Icon(Icons.people, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${household.memberCount} residents',
                  style: GoogleFonts.notoSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.location_on, size: 14, color: AppColors.textSecondary),
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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.edit, size: 14),
                    label: const Text('Edit Residents', style: TextStyle(fontSize: 12)),
                    onPressed: () => _handleEditResidents(context),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                  tooltip: 'Delete Record',
                  onPressed: () => _handleDelete(context),
                ),
              ],
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
            const Icon(Icons.settings, size: 64, color: AppColors.textSecondary),
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
