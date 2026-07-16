import 'package:flutter/material.dart';
import 'package:fm_sons/utils/constants/color_string.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const BottomNav({super.key, required this.currentIndex, this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: FMSons.accent,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined),
          activeIcon: Icon(Icons.receipt_long),
          label: 'Invoices',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.note_alt_outlined),
          activeIcon: Icon(Icons.note_alt),
          label: 'Notes',
        ),
      ],
    );
  }
}
