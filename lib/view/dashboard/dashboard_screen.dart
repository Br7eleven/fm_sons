import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fm_sons/utils/constants/color_string.dart';
import 'package:fm_sons/view/invoice/create_invoice_screen.dart';
import 'package:fm_sons/view/invoice/controller/create_invoice_controller.dart';
import 'package:fm_sons/view/dashboard/widgets/dashborad_app_bar.dart';
import 'package:fm_sons/view/dashboard/widgets/segmented_toggle.dart';
import 'package:fm_sons/view/dashboard/widgets/transaction_list_tab.dart';
import 'package:fm_sons/view/dashboard/widgets/party_list_tab.dart';
import 'package:fm_sons/view/masters/customer/add_party_form_sheet.dart';
import 'package:fm_sons/view/masters/customer/customer_controller.dart';
import 'package:fm_sons/view/masters/customer/customer_model.dart';
import '.././shared/bottom_nav.dart';
import '.././shared/app_drawer.dart';

import '../invoice/invoice_history_tab.dart';
import 'package:fm_sons/data/local/models/note_model.dart';
import 'package:fm_sons/view/notes/note_controller.dart';
import 'package:fm_sons/view/notes/note_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  final int initialTab;
  const DashboardScreen({super.key, this.initialTab = 0});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Root: IndexedStack (bottom nav tap only — no swipe)
  int _currentIndex = 0;

  // Inner tabs: Transaction(0) ↔ Party(1) — swipeable PageView
  late final PageController _innerPageController;

  // Scroll-aware FAB
  bool _isPillVisible = true;
  double _lastScrollPos = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    _innerPageController = PageController();
  }

  @override
  void dispose() {
    _innerPageController.dispose();
    super.dispose();
  }

  Future<void> _openCreateInvoiceFlow() async {
    if (!mounted) return;
    await Navigator.push(
      context, MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()),
    );
    if (mounted) context.read<InvoiceController>().loadSavedInvoices();
  }

  Future<void> _openAddPartyFlow() async {
    final ctrl = context.read<CustomerController>();
    final result = await showModalBottomSheet<Customer>(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const AddPartyFormSheet(),
    );
    if (result != null && mounted) {
      try {
        await ctrl.addOrGetCustomer(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Party added')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
        }
      }
    }
  }

  void _handleBottomNavTap(int index) {
    setState(() {
      _currentIndex = index;
      _lastScrollPos = 0;
      _isPillVisible = true;
    });
    if (index == 0 && _innerPageController.hasClients) {
      _innerPageController.jumpToPage(0);
    }
  }

  void _onSegmentChanged(int index) {
    setState(() {
      _lastScrollPos = 0;
      _isPillVisible = true;
    });
    _innerPageController.animateToPage(
      index, duration: const Duration(milliseconds: 250), curve: Curves.easeOut,
    );
  }

  String _getCurrentRoute() {
    switch (_currentIndex) {
      case 1: return 'invoices';
      case 2: return 'notes';
      default: return 'dashboard';
    }
  }

  // Single unified AppBar across all pages for smooth swipe transition.
  PreferredSizeWidget _buildAppBar() {
    return const DashboardAppBar();
  }

  // Dashboard page extracted as build method — called from _DashboardPage widget below
  Widget _buildDashboardPage(BuildContext context) {
    return Column(
      children: [
        SegmentedToggle(pageController: _innerPageController, onChanged: _onSegmentChanged),
        Expanded(
          child: PageView(
            controller: _innerPageController,
            children: [
              TransactionListTab(onAddTxn: _openCreateInvoiceFlow),
              const PartyListTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (_currentIndex != 0 && _currentIndex != 2) return false;
            final d = n.metrics.pixels - _lastScrollPos;
            if (d.abs() > 8) {
              if (d > 0 && _isPillVisible) {
                setState(() => _isPillVisible = false);
              } else if (d < 0 && !_isPillVisible) {
                setState(() => _isPillVisible = true);
              }
            }
            _lastScrollPos = n.metrics.pixels;
            return false;
          },
          child: IndexedStack(
            index: _currentIndex,
            children: [
              _buildDashboardPage(context),
              const InvoiceHistoryTab(),
              const _NotesTabContent(),
            ],
          ),
        ),
        // Dashboard floating pill
        if (_currentIndex == 0)
          Positioned(
            bottom: 16, left: 0, right: 0,
            child: AnimatedBuilder(
              animation: _innerPageController,
              builder: (context, _) {
                double page = 0;
                if (_innerPageController.hasClients &&
                    _innerPageController.position.haveDimensions) {
                  page = _innerPageController.page ?? 0;
                }
                final isParty = page.round() == 1;

                return AnimatedSlide(
                  offset: _isPillVisible ? Offset.zero : const Offset(0, 2),
                  duration: const Duration(milliseconds: 250),
                  curve: _isPillVisible ? Curves.easeOutBack : Curves.easeOut,
                  child: AnimatedOpacity(
                    opacity: _isPillVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Center(child: FloatingActionButton.extended(
                      onPressed: isParty ? _openAddPartyFlow : _openCreateInvoiceFlow,
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(isParty ? 'Add New Party' : 'Add New Sale'),
                      backgroundColor: FMSons.accent, foregroundColor: Colors.white,
                      shape: const StadiumBorder(), elevation: 4,
                    )),
                  ),
                );
              },
            ),
          ),
        // Notes floating pill
        if (_currentIndex == 2)
          Positioned(bottom: 16, left: 0, right: 0, child: AnimatedSlide(
            offset: _isPillVisible ? Offset.zero : const Offset(0, 2),
            duration: const Duration(milliseconds: 250),
            curve: _isPillVisible ? Curves.easeOutBack : Curves.easeOut,
            child: AnimatedOpacity(
              opacity: _isPillVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Center(child: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const NoteDetailScreen()));
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Note'),
                backgroundColor: FMSons.accent, foregroundColor: Colors.white,
                shape: const StadiumBorder(), elevation: 4,
              )),
            ),
          )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: AppDrawer(currentRoute: _getCurrentRoute(), onTabChange: (i) {
        if (i == 0) { _lastScrollPos = 0; _isPillVisible = true; }
        _handleBottomNavTap(i);
      }),
      drawerEdgeDragWidth: MediaQuery.of(context).size.width * 0.25,
      bottomNavigationBar: BottomNav(currentIndex: _currentIndex, onTap: _handleBottomNavTap),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.deferToChild,
        child: _buildBody(),
      ),
    );
  }
}

// Stripped Notes content — no own Scaffold/AppBar/BottomNav/Drawer.
// Uses the outer Dashboard Scaffold for all chrome.
class _NotesTabContent extends StatefulWidget {
  const _NotesTabContent();
  @override
  State<_NotesTabContent> createState() => _NotesTabContentState();
}

class _NotesTabContentState extends State<_NotesTabContent> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NoteController>();
    final notes = controller.notes;

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => controller.search(v),
            decoration: InputDecoration(
              hintText: 'Search notes...',
              prefixIcon: const Icon(Icons.search, size: 18),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              suffixIcon: controller.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        controller.clearSearch();
                      },
                    )
                  : null,
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: FMSons.accent, width: 1.5),
              ),
            ),
          ),
        ),

        // Notes list
        Expanded(
          child: controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : controller.hasError
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(controller.errorMessage ?? 'Failed to load notes'),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => controller.refresh(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : notes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.note_add_outlined, size: 64, color: Theme.of(context).disabledColor),
                              Text('No notes yet', style: TextStyle(color: Colors.grey.shade600)),
                            ],
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                          children: notes.map((n) => _MiniNoteTile(note: n)).toList(),
                        ),
        ),
      ],
    );
  }
}

class _MiniNoteTile extends StatelessWidget {
  final Note note;
  const _MiniNoteTile({required this.note});

  String _fmtDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        if (diff.inMinutes == 0) return 'Just now';
        return '${diff.inMinutes} min ago';
      }
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => NoteDetailScreen(note: note)));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    note.body,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _fmtDate(note.updatedAt),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
