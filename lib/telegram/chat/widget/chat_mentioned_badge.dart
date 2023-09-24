import 'package:flutter/material.dart';

class ChatMentionedBadge extends StatelessWidget {
  const ChatMentionedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:  BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.primary,
      ),
      padding: const EdgeInsets.all(4.5),
      child: const Text(
        '@',
        style: TextStyle(
          fontSize: 13,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
