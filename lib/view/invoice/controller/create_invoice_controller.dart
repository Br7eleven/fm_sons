import 'package:flutter/material.dart';
import 'package:fm_sons/view/masters/customer/customer_model.dart';

class InvoiceItem {
  final String name;
  final String unit;
  final int quantity;
  final double rate;

  InvoiceItem({
    required this.name,
    required this.unit,
    required this.quantity,
    required this.rate,
  });

  double get total => quantity * rate;
}

class InvoiceController extends ChangeNotifier {
  String amountInWords = "";
  final List<InvoiceItem> _items = [];

  final String invoiceNumber = 'INV-0001';
  DateTime _invoiceDate = DateTime.now();

  DateTime get invoiceDate => _invoiceDate;

  void updateInvoiceDate(DateTime date) {
    _invoiceDate = date;
    notifyListeners();
  }

  // Invoice Items
  List<InvoiceItem> get items => _items;

  void addItem(InvoiceItem item) {
    _items.add(item);
    updateAmountInWords();
    notifyListeners();
  }

  void removeItem(int index) {
    _items.removeAt(index);
    updateAmountInWords();
    notifyListeners();
  }

  double get totalAmount {
    return _items.fold(0, (sum, item) => sum + item.total);
  }

  Customer? _customer;

  Customer? get customer => _customer;

  /// Derived value (NO duplication)
  String? get customerName => _customer?.name;

  void setCustomer(Customer customer) {
    _customer = customer;
    notifyListeners();
  }

  /// Optional: when user types a new name directly
  void setCustomerName(String name) {
    _customer = Customer.temp(name); // temporary unsaved customer
    notifyListeners();
  }

  //amount in words
  void updateAmountInWords() {
    if (totalAmount == 0) {
      amountInWords = "Zero Rupees only";
    } else {
      // totalAmount ko integer mein convert kar ke conversion function ko bhej rahe hain
      amountInWords = "${_numberToEnglish(totalAmount.floor())} Rupees only";
    }
  }

  // Numbers ko Words mein badalne ki logic
  String _numberToEnglish(int n) {
    if (n < 0) return "Negative ${_numberToEnglish(-n)}";
    if (n <= 20) {
      return [
        "",
        "One",
        "Two",
        "Three",
        "Four",
        "Five",
        "Six",
        "Seven",
        "Eight",
        "Nine",
        "Ten",
        "Eleven",
        "Twelve",
        "Thirteen",
        "Fourteen",
        "Fifteen",
        "Sixteen",
        "Seventeen",
        "Eighteen",
        "Nineteen",
        "Twenty",
      ][n];
    }
    if (n < 100) {
      return [
            "",
            "",
            "Twenty",
            "Thirty",
            "Forty",
            "Fifty",
            "Sixty",
            "Seventy",
            "Eighty",
            "Ninety",
          ][n ~/ 10] +
          (n % 10 != 0 ? " ${_numberToEnglish(n % 10)}" : "");
    }
    if (n < 1000) {
      return "${_numberToEnglish(n ~/ 100)} Hundred${n % 100 != 0 ? " and ${_numberToEnglish(n % 100)}" : ""}";
    }
    if (n < 100000) {
      return "${_numberToEnglish(n ~/ 1000)} Thousand${n % 1000 != 0 ? " ${_numberToEnglish(n % 1000)}" : ""}";
    }
    if (n < 10000000) {
      // Lakhs handle karne ke liye
      return "${_numberToEnglish(n ~/ 100000)} Lakh${n % 100000 != 0 ? " ${_numberToEnglish(n % 100000)}" : ""}";
    }
    return n.toString();
  }
}
