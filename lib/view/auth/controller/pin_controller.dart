import 'package:flutter/material.dart';

class PinController extends ChangeNotifier {
  static const int pinLength = 6;
  static const String correctPin = '123456'; // 🔒 change later

  final List<int> _enteredPin = [];

  List<int> get enteredPin => _enteredPin;

  bool get isComplete => _enteredPin.length == pinLength;

  void addDigit(int digit) {
    if (_enteredPin.length >= pinLength) return;
    _enteredPin.add(digit);
    notifyListeners();
  }

  void removeDigit() {
    if (_enteredPin.isEmpty) return;
    _enteredPin.removeLast();
    notifyListeners();
  }

  bool validatePin() {
    final pin = _enteredPin.join();
    return pin == correctPin;
  }

  void clear() {
    _enteredPin.clear();
    notifyListeners();
  }
}
