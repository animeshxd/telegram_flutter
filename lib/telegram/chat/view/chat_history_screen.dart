import 'package:flutter/material.dart';
import 'package:tdffi/td.dart' as t;
import '../widget/chat_avatar.dart';
import '../../auth/widget/auth_route_manager.dart';
import '../models/chat.dart';

class ChatHistoryScreen extends StatelessWidget {
  const ChatHistoryScreen({super.key, required this.chat, this.user});
  final Chat chat;
  final t.User? user;
  static const String subpath = 'history';
  static const String path = '/chat/history';

  @override
  Widget build(BuildContext context) {
    return AuthRouteManager(
      child: Scaffold(
        appBar: AppBar(
          //TODO: show Title, Photo, chat type / member count
          title: ListTile(
            leading: ChatAvatar(chat: chat),
            title: Text(
              chat.title,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: const Text('test'),
            contentPadding: const EdgeInsets.all(0),
          ),
          titleSpacing: 0,
          actions: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
          ],
        ),
      ),
    );
  }
}
