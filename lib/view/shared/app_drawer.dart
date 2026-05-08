import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../dashboard/dashboard_screen.dart';
import '../notes/notes_screen.dart';
import '../settings/theme_controller.dart';

class AppDrawer extends StatelessWidget {
  final String? currentRoute;
  final Function(int)? onTabChange;

  const AppDrawer({super.key, this.currentRoute, this.onTabChange});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Drawer Header
              _DrawerHeader(),
              const SizedBox(height: 8),

              /// Navigation Items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _DrawerItem(
                      icon: Icons.home_outlined,
                      title: 'Dashboard',
                      subtitle: 'Overview & stats',
                      isActive: currentRoute == 'dashboard',
                      onTap: () {
                        _handleNavigation(context, 0);
                      },
                    ),
                    const SizedBox(height: 4),
                    _DrawerItem(
                      icon: Icons.business_outlined,
                      title: 'FM Sons Profile',
                      subtitle: 'Business settings',
                      isActive: currentRoute == 'profile',
                      onTap: () {
                        Navigator.pop(context);
                        _showComingSoon(context, 'FM Sons Profile');
                      },
                    ),
                    const SizedBox(height: 4),
                    _DrawerItem(
                      icon: Icons.people_outline,
                      title: 'Clients',
                      subtitle: 'Manage customers',
                      isActive: currentRoute == 'clients',
                      onTap: () {
                        _handleNavigation(context, 2);
                      },
                    ),
                    const SizedBox(height: 4),
                    _DrawerItem(
                      icon: Icons.note_alt_outlined,
                      title: 'Notes',
                      subtitle: 'Quick notes & memos',
                      isActive: currentRoute == 'notes',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotesScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    _DrawerItem(
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                      subtitle: 'App preferences',
                      isActive: currentRoute == 'settings',
                      onTap: () {
                        _handleNavigation(context, 3);
                      },
                    ),
                  ],
                ),
              ),

              /// Theme Switcher
              const _ThemeSwitcher(),

              /// App Version Footer
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Text(
                  'FM Sons v1.0.2',
                  style: TextStyle(
                    color: Colors.blueGrey.shade400,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature is coming soon')));
  }

  void _handleNavigation(BuildContext context, int tabIndex) {
    Navigator.pop(context); // Close drawer first

    // Check if we're already on the dashboard
    final isOnDashboard =
        context.findAncestorWidgetOfExactType<DashboardScreen>() != null;

    if (isOnDashboard && onTabChange != null) {
      // We're on dashboard, use the callback to change tabs
      onTabChange!(tabIndex);
    } else if (!isOnDashboard) {
      // Navigate to dashboard with specific tab
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardScreen(initialTab: tabIndex),
          settings: const RouteSettings(name: '/home'),
        ),
        (route) => route.isFirst,
      );
    }
  }
}

/* -------------------------------------------------------------------------- */
/*                            DRAWER HEADER                                   */
/* -------------------------------------------------------------------------- */

class _DrawerHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          /// App Icon/Logo
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Icon(
                Icons.receipt_long,
                color: Color(0xFF1E3A8A),
                size: 32,
              ),
            ),
          ),
          const SizedBox(width: 16),

          /// App Name
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FM Sons',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Billing App',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                            DRAWER ITEM                                     */
/* -------------------------------------------------------------------------- */

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isActive;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF1E3A8A).withValues(alpha: 0.08)
            : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? const Color(0xFF1E3A8A).withValues(alpha: 0.3)
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          width: isActive ? 2 : 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF1E3A8A)
                : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isActive
                ? Colors.white
                : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isActive
                ? const Color(0xFF1E3A8A)
                : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: isActive
                ? const Color(0xFF1E3A8A).withValues(alpha: 0.7)
                : Colors.grey.shade600,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: isActive ? const Color(0xFF1E3A8A) : Colors.grey.shade400,
          size: 20,
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                            THEME SWITCHER                                  */
/* -------------------------------------------------------------------------- */

class _ThemeSwitcher extends StatelessWidget {
  const _ThemeSwitcher();

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.palette_outlined,
                size: 18,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                'Theme',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ThemeOption(
                  icon: Icons.light_mode_outlined,
                  label: 'Light',
                  isSelected: themeController.isLightMode,
                  onTap: () => themeController.setTheme(ThemeMode.light),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ThemeOption(
                  icon: Icons.dark_mode_outlined,
                  label: 'Dark',
                  isSelected: themeController.isDarkMode,
                  onTap: () => themeController.setTheme(ThemeMode.dark),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ThemeOption(
                  icon: Icons.brightness_auto_outlined,
                  label: 'System',
                  isSelected: themeController.isSystemMode,
                  onTap: () => themeController.setTheme(ThemeMode.system),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                            THEME OPTION                                    */
/* -------------------------------------------------------------------------- */

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1E3A8A).withValues(alpha: isDark ? 0.3 : 0.12)
              : (isDark ? Colors.grey.shade900 : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1E3A8A)
                : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? const Color(0xFF1E3A8A)
                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? const Color(0xFF1E3A8A)
                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
