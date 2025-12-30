import 'package:flutter/material.dart';

class AvatarWidget extends StatelessWidget {
  final double size;
  final bool isOnline;

  const AvatarWidget({super.key, this.size = 36, this.isOnline = true});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: size / 2,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: const AssetImage(
            'assets/images/avatar.png', // replace with your asset
          ),
        ),

        // 🔹 Online / Offline indicator
        Positioned(
          bottom: 2,
          right: 2,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: isOnline ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
