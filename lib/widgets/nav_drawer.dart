import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class NavDrawer extends StatelessWidget {
  final int activeIndex;
  final Function(int) onNavigate;

  const NavDrawer({
    super.key,
    required this.activeIndex,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final officer = appState.currentOfficer;
    final isDark = appState.isDarkMode;

    return Drawer(
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white24,
                  child: Text(
                    officer != null ? officer.name[0] : 'G',
                    style: GoogleFonts.notoSans(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  officer?.name ?? 'Guest',
                  style: GoogleFonts.notoSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  officer?.id ?? '',
                  style: GoogleFonts.notoSans(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: officer?.isAdmin == true
                        ? AppColors.accent
                        : Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    officer?.role ?? 'Guest',
                    style: GoogleFonts.notoSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 12, color: Colors.white70),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        officer?.district ?? '',
                        style: GoogleFonts.notoSans(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildMenuItem(
                  context,
                  index: 0,
                  icon: Icons.dashboard,
                  label: 'Dashboard',
                  isDark: isDark,
                ),
                _buildMenuItem(
                  context,
                  index: 1,
                  icon: Icons.list_alt,
                  label: 'Data Entry Phase 1',
                  isDark: isDark,
                ),
                _buildMenuItem(
                  context,
                  index: 2,
                  icon: Icons.person_add,
                  label: 'Data Entry Phase 2',
                  isDark: isDark,
                ),
                _buildMenuItem(
                  context,
                  index: 3,
                  icon: Icons.track_changes,
                  label: 'Progress Tracker',
                  isDark: isDark,
                ),
                _buildMenuItem(
                  context,
                  index: 4,
                  icon: Icons.bar_chart,
                  label: 'Metrics & Analytics',
                  isDark: isDark,
                ),
                const Divider(indent: 16, endIndent: 16),
                _buildMenuItem(
                  context,
                  index: 5,
                  icon: Icons.settings,
                  label: 'Settings',
                  isDark: isDark,
                ),
                _buildMenuItem(
                  context,
                  index: 6,
                  icon: Icons.logout,
                  label: 'Logout',
                  isDark: isDark,
                  isDestructive: true,
                ),
              ],
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? const Color(0xFF444444) : AppColors.divider,
                ),
              ),
            ),
            child: Text(
              'v2.4.1 | Census of India 2024',
              style: GoogleFonts.notoSans(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
    required bool isDark,
    bool isDestructive = false,
  }) {
    final isActive = activeIndex == index && !isDestructive;
    final color = isDestructive
        ? AppColors.error
        : isActive
            ? AppColors.accent
            : isDark
                ? AppColors.darkTextPrimary
                : AppColors.textPrimary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.accent.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: ListTile(
        leading: Icon(icon, color: color, size: 22),
        title: Text(
          label,
          style: GoogleFonts.notoSans(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: color,
          ),
        ),
        onTap: () => onNavigate(index),
        dense: true,
        visualDensity: VisualDensity.compact,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      ),
    );
  }
}
