import 'package:flutter/material.dart';

class ChatLabel extends StatelessWidget {
  const ChatLabel({
    super.key,
    this.decoration,
    required this.label,
  });

  final Decoration? decoration;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: decoration ??
          BoxDecoration(
            border: Border.all(color: Colors.red),
            borderRadius: const BorderRadius.all(Radius.circular(3)),
          ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 8),
      ),
    );
  }
}
