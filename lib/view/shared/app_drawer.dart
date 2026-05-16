import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../dashboard/dashboard_screen.dart';
import '../letterheads/letterheads_screen.dart';
import '../masters/customer/clients_tab.dart';
import '../notes/notes_screen.dart';
import '../settings/about_screen.dart';
import '../settings/company_profile_controller.dart';
import '../settings/company_profile_screen.dart';
import '../settings/settings_tab.dart';
import '../settings/theme_controller.dart';

class AppDrawer extends StatelessWidget {
  final String? currentRoute;
  final Function(int)? onTabChange;

  const AppDrawer({super.key, this.currentRoute, this.onTabChange});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DrawerHeader(),
            const SizedBox(height: 4),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  _DrawerItem(
                    icon: Icons.home_outlined,
                    title: 'Dashboard',
                    isActive: currentRoute == 'dashboard',
                    onTap: () => _handleNavigation(context, 0),
                  ),
                  _DrawerItem(
                    icon: Icons.people_outline,
                    title: 'Clients',
                    isActive: currentRoute == 'clients',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Scaffold(
                            appBar: AppBar(
                              title: const Text(
                                'Clients',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                              centerTitle: true,
                              elevation: 0,
                            ),
                            body: const ClientsTab(),
                          ),
                        ),
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.note_alt_outlined,
                    title: 'Notes',
                    isActive: currentRoute == 'notes',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotesScreen()),
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.article_outlined,
                    title: 'Letterheads',
                    isActive: currentRoute == 'letterheads',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LetterheadsScreen(),
                        ),
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    isActive: currentRoute == 'settings',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Scaffold(
                            appBar: AppBar(
                              title: const Text(
                                'Settings',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              centerTitle: true,
                              elevation: 0,
                            ),
                            body: const SettingsTab(),
                          ),
                        ),
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.info_outline,
                    title: 'About',
                    isActive: currentRoute == 'about',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AboutScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            const _ThemeSwitcher(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'FM Sons v1.0.2',
                    style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 11),
                  ),
                  const Text(
                    'BR7 Technologies & Co.',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF00CFFF),
                      letterSpacing: 0.3,
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

  void _handleNavigation(BuildContext context, int tabIndex) {
    Navigator.pop(context);
    final isOnDashboard =
        context.findAncestorWidgetOfExactType<DashboardScreen>() != null;
    if (isOnDashboard && onTabChange != null) {
      onTabChange!(tabIndex);
    } else if (!isOnDashboard) {
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
    final name = context.select<CompanyProfileController, String>((p) => p.name);
    final tagline = context.select<CompanyProfileController, String>((p) => p.tagline);
    final logoPath = context.select<CompanyProfileController, String?>((p) => p.logoPath);

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CompanyProfileScreen()),
        );
      },
      child: Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _LogoAvatar(logoPath: logoPath, name: name),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  tagline.isNotEmpty ? tagline : 'Billing App',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                            LOGO AVATAR                                     */
/* -------------------------------------------------------------------------- */

class _LogoAvatar extends StatelessWidget {
  final String? logoPath;
  final String name;

  const _LogoAvatar({required this.logoPath, required this.name});

  String _initials() {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'FM';
    if (parts.length == 1) return parts[0].substring(0, parts[0].length.clamp(1, 2)).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: logoPath != null
          ? Image.file(File(logoPath!), fit: BoxFit.cover)
          : Center(
              child: Text(
                _initials(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E3A8A),
                ),
              ),
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
  final bool isActive;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = const Color(0xFF1E3A8A);

    return ListTile(
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      tileColor: isActive ? color.withValues(alpha: 0.08) : Colors.transparent,
      leading: Icon(
        icon,
        size: 20,
        color: isActive ? color : Theme.of(context).iconTheme.color?.withValues(alpha: 0.7),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          color: isActive ? color : Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      trailing: isActive
          ? Icon(Icons.circle, size: 8, color: color)
          : null,
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
    final color = const Color(0xFF1E3A8A);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(
        children: [
          Icon(
            Icons.palette_outlined,
            size: 16,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          const SizedBox(width: 8),
          Text(
            'Theme',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const Spacer(),
          Container(
            height: 32,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ThemeSegment(
                  icon: Icons.light_mode_outlined,
                  tooltip: 'Light',
                  isSelected: themeController.isLightMode,
                  isFirst: true,
                  isLast: false,
                  onTap: () => themeController.setTheme(ThemeMode.light),
                  color: color,
                  isDark: isDark,
                ),
                _ThemeSegment(
                  icon: Icons.dark_mode_outlined,
                  tooltip: 'Dark',
                  isSelected: themeController.isDarkMode,
                  isFirst: false,
                  isLast: false,
                  onTap: () => themeController.setTheme(ThemeMode.dark),
                  color: color,
                  isDark: isDark,
                ),
                _ThemeSegment(
                  icon: Icons.brightness_auto_outlined,
                  tooltip: 'System',
                  isSelected: themeController.isSystemMode,
                  isFirst: false,
                  isLast: true,
                  onTap: () => themeController.setTheme(ThemeMode.system),
                  color: color,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeSegment extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isSelected;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;
  final Color color;
  final bool isDark;

  const _ThemeSegment({
    required this.icon,
    required this.tooltip,
    required this.isSelected,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 32,
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.horizontal(
              left: isFirst ? const Radius.circular(7) : Radius.zero,
              right: isLast ? const Radius.circular(7) : Radius.zero,
            ),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          ),
        ),
      ),
    );
  }
}
