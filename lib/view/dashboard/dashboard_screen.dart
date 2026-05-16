import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fm_sons/view/invoice/create_invoice_screen.dart';
import 'package:fm_sons/view/dashboard/widgets/dashborad_app_bar.dart';
import 'package:fm_sons/view/dashboard/widgets/overview_card.dart';
import 'package:fm_sons/view/dashboard/widgets/stat_card.dart';
import 'package:fm_sons/view/dashboard/widgets/quick_actions_grid.dart';
import '.././shared/bottom_nav.dart';
import '.././shared/app_drawer.dart';

import '../../data/local/dao/invoice_dao.dart';
import '../invoice/invoice_history_tab.dart';
import '../masters/customer/clients_tab.dart';
import '../notes/notes_screen.dart';
import '../settings/settings_tab.dart';

class DashboardScreen extends StatefulWidget {
  final int initialTab;

  const DashboardScreen({super.key, this.initialTab = 0});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  final InvoiceDao _invoiceDao = InvoiceDao();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'PKR ',
    decimalDigits: 0,
  );

  late int _currentIndex;
  bool _isLoading = true;
  String? _loadError;
  int _totalInvoices = 0;
  int _todayInvoices = 0;
  double _pendingAmount = 0;
  double _paidAmount = 0;
  double _todayBilledAmount = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    WidgetsBinding.instance.addObserver(this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadDashboardData();
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final summary = await _invoiceDao.getInvoiceStatusSummary();
      final invoices = await _invoiceDao.getAllInvoices();

      final now = DateTime.now();
      var todayInvoices = 0;
      var todayBilled = 0.0;

      for (final invoice in invoices) {
        final parsedDate = DateTime.tryParse(invoice.invoiceDate);
        if (parsedDate == null) continue;

        final localDate = parsedDate.toLocal();
        final isToday =
            localDate.year == now.year &&
            localDate.month == now.month &&
            localDate.day == now.day;

        if (isToday) {
          todayInvoices += 1;
          todayBilled += invoice.total;
        }
      }

      if (!mounted) return;
      setState(() {
        _totalInvoices = (summary['total_count'] ?? 0).toInt();
        _pendingAmount = (summary['pending_amount'] ?? 0).toDouble();
        _paidAmount = (summary['paid_amount'] ?? 0).toDouble();
        _todayInvoices = todayInvoices;
        _todayBilledAmount = todayBilled;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Unable to load dashboard data. Pull to refresh.';
        _isLoading = false;
      });
    }
  }

  Future<void> _openCreateInvoiceFlow() async {
    // Don't reset draft - it should be preserved when navigating back
    // Draft is only cleared after successful save or explicit discard
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()),
    );

    if (!mounted) return;
    await _loadDashboardData();
  }

  String _formatCurrency(num value) => _currencyFormat.format(value);

  void _handleTabChanged(int index) {
    if (index == 2) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => const NotesScreen(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      ).then((result) {
        if (result is int && mounted) {
          setState(() => _currentIndex = result);
        }
      });
      return;
    }
    setState(() => _currentIndex = index);
  }

  String _getCurrentRoute() {
    switch (_currentIndex) {
      case 1:
        return 'invoices';
      default:
        return 'dashboard';
    }
  }

  PreferredSizeWidget _buildAppBar() {
    switch (_currentIndex) {
      case 1:
        return InvoiceHistoryAppBar(
          onSettingsTap: () => _navigateToSettings(),
        );
      default:
        return const DashboardAppBar();
    }
  }

  void _navigateToSettings() {
    Navigator.of(context).push(
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
  }

  Widget _buildBody() {
    return IndexedStack(
      index: _currentIndex,
      children: [
        _DashboardOverviewTab(
          isLoading: _isLoading,
          loadError: _loadError,
          billedAmountLabel: _formatCurrency(_todayBilledAmount),
          pendingAmountLabel: _formatCurrency(_pendingAmount),
          paidAmountLabel: _formatCurrency(_paidAmount),
          totalInvoices: _totalInvoices,
          todayInvoices: _todayInvoices,
          onNewInvoiceTap: _openCreateInvoiceFlow,
          onOpenInvoicesTap: () => setState(() => _currentIndex = 1),
          onOpenClientsTap: () {
            Navigator.of(context).push(
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
          onRefresh: _loadDashboardData,
        ),
        const InvoiceHistoryTab(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: AppDrawer(
        currentRoute: _getCurrentRoute(),
        onTabChange: _handleTabChanged,
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        onTap: _handleTabChanged,
      ),
      body: _buildBody(),
    );
  }
}

class _DashboardOverviewTab extends StatelessWidget {
  final bool isLoading;
  final String? loadError;
  final String billedAmountLabel;
  final String pendingAmountLabel;
  final String paidAmountLabel;
  final int totalInvoices;
  final int todayInvoices;
  final Future<void> Function()? onNewInvoiceTap;
  final VoidCallback onOpenInvoicesTap;
  final VoidCallback onOpenClientsTap;
  final Future<void> Function() onRefresh;

  const _DashboardOverviewTab({
    required this.isLoading,
    required this.loadError,
    required this.billedAmountLabel,
    required this.pendingAmountLabel,
    required this.paidAmountLabel,
    required this.totalInvoices,
    required this.todayInvoices,
    required this.onNewInvoiceTap,
    required this.onOpenInvoicesTap,
    required this.onOpenClientsTap,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OverviewCard(
            billedAmountLabel: billedAmountLabel,
            trendLabel: todayInvoices == 0
                ? 'No invoices today'
                : '$todayInvoices today',
          ),
          const SizedBox(height: 16),
          StatCardRow(
            pendingAmountLabel: pendingAmountLabel,
            paidAmountLabel: paidAmountLabel,
            totalInvoices: totalInvoices,
            todayInvoices: todayInvoices,
          ),
          const SizedBox(height: 24),
          if (loadError != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      loadError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                  TextButton(onPressed: onRefresh, child: const Text('Retry')),
                ],
              ),
            ),
          QuickActionGrid(
            onNewInvoiceTap: onNewInvoiceTap,
            onHistoryTap: onOpenInvoicesTap,
            onClientsTap: onOpenClientsTap,
          ),
          if (isLoading) ...[
            const SizedBox(height: 20),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }
}
