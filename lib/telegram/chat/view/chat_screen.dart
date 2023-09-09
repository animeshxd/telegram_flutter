import 'package:flutter/material.dart';
import 'package:telegram_flutter/telegram/auth/bloc/auth_bloc.dart';

// void main() => runApp(const MainApp());

// class MainApp extends StatelessWidget {
//   const MainApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       theme: ThemeData(useMaterial3: true),
//       title: 'Telegram',
//       home: const ChatScreen(),
//     );
//   }
// }

class ChatScreen extends StatefulWidget {
  final AuthStateCurrentAccountReady? state;
  const ChatScreen({super.key, this.state});
  static const path = '/chat';
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Telegram"),
      ),
      drawer: Drawer(
        child: ListView(
          children: const [DrawerHeader(child: Text(''))],
        ),
      ),
      body: const Center(
        child: Text('Hello World'),
      ),
    );
  }
}
