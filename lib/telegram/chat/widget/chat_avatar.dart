import 'package:flutter/material.dart';

class ChatColorAvatar extends StatelessWidget {
  const ChatColorAvatar({super.key, required this.id, required this.child});
  final int id;
  final Widget child;

  final List<Color> colors = const [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.indigo,
    Colors.deepOrange,
    Colors.grey,
    Colors.deepPurpleAccent
  ];
  Color get color => colors[[0, 7, 4, 1, 6, 3, 5][(id % 7)]];

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(backgroundColor: color, child: child);
  }
}
