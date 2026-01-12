import 'package:flutter/material.dart';
import '../../controller/create_invoice_controller.dart';

/// Base class for all invoice templates
/// Optimized for A4 Letterhead display without overflow.
abstract class InvoiceTemplate extends StatelessWidget {
  final InvoiceController invoice;
  

  const InvoiceTemplate({super.key, required this.invoice});

  Widget buildHeader(BuildContext context);
  Widget buildInvoiceInfo(BuildContext context);
  Widget buildItems(BuildContext context);
  Widget buildTotals(BuildContext context);
  Widget buildFooter(BuildContext context);
  

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.contain, // Scale karega screen size ke mutabiq
        child: Container(
          width: 794, // Standard A4 Width at 96 DPI
          height: 1123, // Standard A4 Height at 96 DPI
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 40),
          child: Column(
            children: [
              // Header fixed rahay ga
              buildHeader(context),
              const SizedBox(height: 20),

              // Client info fixed rahay gi
              buildInvoiceInfo(context),
              const SizedBox(height: 15),

              // Items area scrollable/expandable hoga magar page boundary ke andar
              Expanded(
                child: SingleChildScrollView(
                  physics:
                      const NeverScrollableScrollPhysics(), // PDF print ke liye scroll disable
                  child: buildItems(context),
                ),
              ),

              // Totals aur Footer hamesha bottom par "stitch" rahen ge
              const Divider(thickness: 1, color: Colors.black26),
              const SizedBox(height: 10),
              buildTotals(context),

              const SizedBox(height: 30),
              buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }
}
