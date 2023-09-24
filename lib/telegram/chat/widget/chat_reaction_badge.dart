import 'package:flutter/material.dart';

class ChatReactionBadge extends StatelessWidget {
  const ChatReactionBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.pink,
      ),
      padding: const EdgeInsets.all(4.5),
      child: const Icon(
        Icons.favorite,
        color: Colors.white,
        size: 14,
      ),
    );
  }
}
