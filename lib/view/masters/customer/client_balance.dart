import 'package:fm_sons/utils/money_utils.dart';

class ClientBalance {
  final int invoiceCount;
  final double totalInvoiced;
  final double totalReceived;

  const ClientBalance({
    required this.invoiceCount,
    required this.totalInvoiced,
    required this.totalReceived,
  });

  double get totalOutstanding => normalizeMoney(totalInvoiced - totalReceived);
}
