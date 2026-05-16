import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _BrandCard(),
          const SizedBox(height: 20),
          _InfoSection(
            title: 'Developer',
            items: const [
              _InfoRow(icon: Icons.business_outlined,       label: 'Company',  value: 'BR7 Technologies & Co.'),
              _InfoRow(icon: Icons.language_outlined,       label: 'Website',  value: 'br7tech.dev', isLink: true),
              _InfoRow(icon: Icons.email_outlined,          label: 'Contact',  value: 'hello@br7tech.dev', isLink: true, isEmail: true),
            ],
          ),
          const SizedBox(height: 20),
          _InfoSection(
            title: 'Application',
            items: const [
              _InfoRow(icon: Icons.receipt_long_outlined,   label: 'App',      value: 'FM SONS Billing'),
              _InfoRow(icon: Icons.tag_outlined,            label: 'Version',  value: '1.0.0'),
              _InfoRow(icon: Icons.android_outlined,        label: 'Platform', value: 'Android'),
            ],
          ),
          const SizedBox(height: 20),
          _LegalSection(),
          const SizedBox(height: 32),
          Center(
            child: Text(
              '© 2026 BR7 Technologies & Co. All rights reserved.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

/* ─────────────────────────── BRAND CARD ─────────────────────────── */

class _BrandCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF1E3A8A);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, primary.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.receipt_long_rounded, size: 40, color: primary),
          ),
          const SizedBox(height: 16),
          const Text(
            'FM SONS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Smart Billing for Everyone',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white30),
            ),
            child: const Text(
              'Built by BR7 Technologies & Co.',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/* ─────────────────────────── INFO SECTION ─────────────────────────── */

class _InfoSection extends StatelessWidget {
  final String title;
  final List<_InfoRow> items;

  const _InfoSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: const Color(0xFF1E3A8A),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                items[i],
                if (i < items.length - 1)
                  Divider(
                    height: 1,
                    indent: 52,
                    color: Theme.of(context).dividerColor,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLink;
  final bool isEmail;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLink = false,
    this.isEmail = false,
  });

  Future<void> _launch() async {
    final uri = isEmail ? Uri.parse('mailto:$value') : Uri.parse('https://$value');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF1E3A8A);
    return InkWell(
      onTap: isLink || isEmail ? _launch : null,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: primary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: (isLink || isEmail) ? primary : Theme.of(context).textTheme.bodyLarge?.color,
                decoration: (isLink || isEmail) ? TextDecoration.underline : TextDecoration.none,
                decorationColor: primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ─────────────────────────── LEGAL SECTION ─────────────────────────── */

class _LegalSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'LEGAL',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: const Color(0xFF1E3A8A),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _LegalTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => const _PolicyDialog(type: _PolicyType.privacy),
                ),
              ),
              Divider(height: 1, indent: 52, color: Theme.of(context).dividerColor),
              _LegalTile(
                icon: Icons.gavel_outlined,
                title: 'Terms of Service',
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => const _PolicyDialog(type: _PolicyType.terms),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegalTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _LegalTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF1E3A8A)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: Theme.of(context).disabledColor),
          ],
        ),
      ),
    );
  }
}

/* ─────────────────────────── POLICY DIALOGS ─────────────────────────── */

enum _PolicyType { privacy, terms }

class _PolicyDialog extends StatelessWidget {
  final _PolicyType type;
  const _PolicyDialog({required this.type});

  @override
  Widget build(BuildContext context) {
    final isPrivacy = type == _PolicyType.privacy;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Icon(
                  isPrivacy ? Icons.privacy_tip_outlined : Icons.gavel_outlined,
                  color: const Color(0xFF1E3A8A),
                ),
                const SizedBox(width: 12),
                Text(
                  isPrivacy ? 'Privacy Policy' : 'Terms of Service',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const Divider(height: 24),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Text(
                isPrivacy ? _privacyText : _termsText,
                style: const TextStyle(fontSize: 13, height: 1.6),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _privacyText = '''
Last updated: May 2026

BR7 Technologies & Co. ("we", "our", or "us") built FM SONS as a local billing application. This policy describes how we handle your information.

DATA COLLECTION
FM SONS stores all data locally on your device. We do not collect, transmit, or store any personal information on external servers. All invoice data, customer records, and notes remain solely on your device.

GOOGLE DRIVE BACKUP
If you choose to use the Google Drive backup feature, data is uploaded to your own Google Drive account using your Google credentials. We do not have access to your Google account or any data stored there.

DATA SECURITY
Since all data is stored locally on your device, security of your data depends on the security of your device. We recommend enabling device lock/PIN protection.

THIRD-PARTY SERVICES
The app does not integrate any analytics, advertising, or third-party tracking services.

CHANGES TO THIS POLICY
We may update this policy from time to time. Updates will be reflected in new app versions.

CONTACT
For questions about this policy, contact us at hello@br7tech.dev or visit br7tech.dev.
''';

const _termsText = '''
Last updated: May 2026

By using FM SONS ("the App"), you agree to these Terms of Service set forth by BR7 Technologies & Co. ("we", "us", "our").

USE OF THE APP
FM SONS is provided for personal and business billing purposes. You may use the App to create invoices, manage clients, and track payments for your legitimate business activities.

INTELLECTUAL PROPERTY
The App, including its design, code, and content, is the property of BR7 Technologies & Co. and is protected by applicable intellectual property laws.

DATA RESPONSIBILITY
You are solely responsible for the accuracy of the data you enter into the App and for maintaining backups of your data. We are not liable for any data loss resulting from device failure, accidental deletion, or other causes.

DISCLAIMER OF WARRANTIES
The App is provided "as is" without warranties of any kind. We do not guarantee that the App will be error-free or uninterrupted.

LIMITATION OF LIABILITY
To the fullest extent permitted by law, BR7 Technologies & Co. shall not be liable for any indirect, incidental, or consequential damages arising from your use of the App.

CHANGES TO TERMS
We reserve the right to modify these terms at any time. Continued use of the App after changes constitutes acceptance of the new terms.

CONTACT
For questions, contact us at hello@br7tech.dev or visit br7tech.dev.
''';
