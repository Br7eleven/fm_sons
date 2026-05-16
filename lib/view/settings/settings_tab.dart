import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/backup/backup_manager.dart';
import 'company_profile_controller.dart';
import 'company_profile_screen.dart';
import '../../data/backup/backup_models.dart';
import '../../data/backup/google_drive_service.dart';
import '../../data/backup/restore_manager.dart';
import '../invoice/controller/create_invoice_controller.dart';

class SettingsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onBackTap;

  const SettingsAppBar({super.key, required this.onBackTap});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        onPressed: onBackTap,
        icon: const Icon(Icons.arrow_back),
      ),
      title: const Text(
        'Settings',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);
}

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final GoogleDriveService _driveService = GoogleDriveService();
  late final BackupManager _backupManager = BackupManager(_driveService);
  late final RestoreManager _restoreManager = RestoreManager(_driveService);

  final DateFormat _backupFormat = DateFormat('MMM d, hh:mm a');

  bool _isConnecting = false;
  bool _isBackingUp = false;
  bool _isRestoring = false;
  DateTime? _lastBackupAt;

  @override
  void initState() {
    super.initState();
    _restoreDriveSession();
  }

  Future<void> _restoreDriveSession() async {
    final restored = await _driveService.restoreSessionSilently();
    if (!mounted) return;

    if (restored) {
      await _refreshBackupMetadata();
      return;
    }

    setState(() {
      _lastBackupAt = null;
    });
  }

  Future<void> _refreshBackupMetadata() async {
    if (!_driveService.isSignedIn) return;

    try {
      final latest = await _driveService.getLatestBackupFile();
      if (!mounted) return;
      setState(() {
        _lastBackupAt = latest?.modifiedTime;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _lastBackupAt = null;
      });
    }
  }

  Future<void> _connectDrive() async {
    if (_isConnecting) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isConnecting = true);
    try {
      await _driveService.ensureSignedIn();
      await _refreshBackupMetadata();
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Google Drive connected')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(_googleSignInErrorMessage(e))),
      );
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  Future<void> _disconnectDrive() async {
    final messenger = ScaffoldMessenger.of(context);
    await _driveService.signOut();
    if (!mounted) return;
    setState(() {
      _lastBackupAt = null;
    });
    messenger.showSnackBar(
      const SnackBar(content: Text('Google Drive disconnected')),
    );
  }

  Future<bool> _confirmLocalNewer(
    DateTime localModified,
    DateTime cloudModified,
  ) async {
    final decision = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Local Data Is Newer'),
          content: Text(
            'Local database is newer than cloud backup.\n\n'
            'Local: ${DateFormat('dd MMM yyyy, hh:mm a').format(localModified)}\n'
            'Cloud: ${DateFormat('dd MMM yyyy, hh:mm a').format(cloudModified)}\n\n'
            'Do you still want to restore from cloud?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Restore Anyway'),
            ),
          ],
        );
      },
    );

    return decision ?? false;
  }

  Future<void> _runBackup() async {
    if (_isBackingUp || _isRestoring) return;
    if (!_driveService.isSignedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connect Google Drive first, then run backup.'),
        ),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final invoiceController = context.read<InvoiceController>();
    setState(() => _isBackingUp = true);
    try {
      final result = await _backupManager.backupDatabase();
      if (!mounted) return;

      if (result.success) {
        await invoiceController.loadSavedInvoices();
        setState(() {
          _lastBackupAt = result.uploadedAt;
        });
        messenger.showSnackBar(SnackBar(content: Text(result.message)));
        return;
      }

      messenger.showSnackBar(SnackBar(content: Text(result.message)));
    } finally {
      if (mounted) {
        setState(() => _isBackingUp = false);
      }
    }
  }

  Future<void> _runRestore() async {
    if (_isRestoring || _isBackingUp) return;
    if (!_driveService.isSignedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connect Google Drive first, then run restore.'),
        ),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isRestoring = true);
    final result = await _restoreManager.restoreLatestBackup(
      conflictPolicy: BackupConflictPolicy.requireConfirmation,
      onLocalNewerConflict: _confirmLocalNewer,
    );

    if (!mounted) return;
    setState(() => _isRestoring = false);

    if (result.outcome == RestoreOutcome.restored) {
      await _refreshBackupMetadata();
    }

    messenger.showSnackBar(SnackBar(content: Text(result.message)));
  }

  Future<void> _toggleConnection(bool enabled) async {
    if (enabled) {
      await _connectDrive();
    } else {
      await _disconnectDrive();
    }
  }

  String _connectionLabel() {
    final email = _driveService.signedInAccountEmail;
    final name = _driveService.signedInAccountName;

    if (email != null && email.isNotEmpty) {
      return 'Connected as $email';
    }

    if (name != null && name.isNotEmpty) {
      return 'Connected as $name';
    }

    return 'Not connected';
  }

  String _googleSignInErrorMessage(Object error) {
    final raw = error.toString();

    if (raw.contains('ApiException: 10') || raw.contains('sign_in_failed')) {
      return 'Google Sign-In setup mismatch (ApiException 10). Add Android OAuth with package com.example.fm_sons and SHA-1 42:BD:8B:5A:70:0F:23:A1:AB:5C:6F:FD:E6:DA:32:9D:BA:13:05:86 in Google Cloud/Firebase.';
    }

    return 'Unable to connect Google Drive: $raw';
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = _driveService.isSignedIn;
    final cp = context.watch<CompanyProfileController>();

    return RefreshIndicator(
      onRefresh: _refreshBackupMetadata,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _SectionTitle(title: 'GENERAL'),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CompanyProfileScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3EEDB),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.business,
                        color: Color(0xFFB08D45),
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cp.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          cp.tagline,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (cp.email.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            cp.email,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _SectionTitle(title: 'CLOUD & DATA'),
          const SizedBox(height: 12),
          _MenuCard(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.cloud_circle_outlined,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Google Drive',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _connectionLabel(),
                            style: TextStyle(
                              color: isConnected
                                  ? Colors.green.shade700
                                  : Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isConnected,
                      onChanged: _isConnecting
                          ? null
                          : (value) {
                              _toggleConnection(value);
                            },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              _SettingsTile(
                icon: _isBackingUp
                    ? Icons.hourglass_top
                    : Icons.backup_outlined,
                title: _isBackingUp ? 'Backing up...' : 'Back up Now',
                subtitle: 'Upload JSON data backup to Drive',
                onTap: _isBackingUp ? null : _runBackup,
              ),
              const Divider(height: 1),
              Builder(
                builder: (context) => _SettingsTile(
                  icon: _isRestoring
                      ? Icons.hourglass_top
                      : Icons.settings_backup_restore,
                  title: _isRestoring ? 'Restoring...' : 'Restore from Backup',
                  subtitle: 'Download latest JSON and overwrite local data',
                  titleColor: Theme.of(context).colorScheme.error,
                  subtitleColor: Theme.of(context).colorScheme.error,
                  iconColor: Theme.of(context).colorScheme.error,
                  onTap: _isRestoring ? null : _runRestore,
                ),
              ),
              if (isConnected) ...[
                const Divider(height: 1),
                _SettingsTile(
                  icon: Icons.logout,
                  title: 'Log out Google account',
                  subtitle: 'Disconnect current Google Drive account',
                  titleColor: Theme.of(context).colorScheme.error,
                  subtitleColor: Theme.of(context).colorScheme.error,
                  iconColor: Theme.of(context).colorScheme.error,
                  onTap: _disconnectDrive,
                ),
              ],
            ],
          ),
          if (_lastBackupAt != null) ...[
            const SizedBox(height: 12),
            Text(
              'Last successful backup: ${_backupFormat.format(_lastBackupAt!)}',
              style: TextStyle(color: Colors.blueGrey.shade400),
            ),
          ],
          const SizedBox(height: 24),
          _SectionTitle(title: 'ABOUT'),
          const SizedBox(height: 12),
          const _MenuCard(
            children: [
              _StaticTile(
                icon: Icons.info_outline,
                title: 'Version',
                trailing: '1.0.2 (Build 45)',
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.blueGrey.shade500,
        fontSize: 13,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final List<Widget> children;

  const _MenuCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color? titleColor;
  final Color? subtitleColor;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.titleColor,
    this.subtitleColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final active = onTap != null;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: (iconColor ?? Colors.blue).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor ?? Colors.blue),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: titleColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: subtitleColor ?? Theme.of(context).textTheme.bodySmall?.color,
        ),
      ),
      trailing: Icon(
        active ? Icons.chevron_right : Icons.lock_outline,
        color: Colors.blueGrey.shade300,
      ),
    );
  }
}

class _StaticTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String trailing;

  const _StaticTile({
    required this.icon,
    required this.title,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.info_outline, color: Colors.blue),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      trailing: Text(
        trailing,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 13),
      ),
    );
  }
}
