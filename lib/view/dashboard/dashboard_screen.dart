import 'package:flutter/material.dart';
import 'package:fm_sons/view/dashboard/widgets/dashborad_app_bar.dart';
import 'package:fm_sons/view/dashboard/widgets/overview_card.dart';
import 'package:fm_sons/view/dashboard/widgets/stat_card.dart';
import 'package:fm_sons/view/dashboard/widgets/quick_actions_grid.dart';
import '.././shared/bottom_nav.dart';

import '../../data/local/dao/invoice_dao.dart';
// import '../../data/local/models/invoice_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final invoiceDao = InvoiceDao();

  // @override
  // void initState() {
  //   super.initState();
  //   _insertTestInvoiceOnce();
  // }

  // Future<void> _insertTestInvoiceOnce() async {
  //   try {
  //     final invoice = InvoiceModel(
  //       invoiceNumber: 'INV-1001',
  //       clientName: 'Govt Works Department',
  //       clientAddress: 'Gilgit Baltistan',
  //       contractId: 1,
  //       invoiceDate: DateTime.now().toIso8601String(),
  //       dueDate: DateTime.now().add(const Duration(days: 30)).toIso8601String(),
  //       subtotal: 40000,
  //       tax: 5000,
  //       total: 45000,
  //       status: 'pending',
  //       createdAt: DateTime.now().toIso8601String(),
  //     );

  //     final id = await invoiceDao.insertInvoice(invoice);
  //     debugPrint('✅ Test Invoice Inserted with ID: $id');
  //   } catch (e) {
  //     debugPrint('⚠️ Invoice insert skipped: $e');
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: const DashboardAppBar(),
      bottomNavigationBar: BottomNav(
        currentIndex: 0,
        onTap: (index) {
          //handle naigation here
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const OverviewCard(),

            // SizedBox(
            //   child: ElevatedButton(
            //     onPressed: () async {
            //       await _insertTestInvoiceOnce();
            //     },
            //     child: const Text('Insert Test Invoice'),
            //   ),
            // ),
            SizedBox(height: 16),
            StatCardRow(),
            SizedBox(height: 24),
            QuickActionGrid(),
          ],
        ),
      ),
    );
  }
}
