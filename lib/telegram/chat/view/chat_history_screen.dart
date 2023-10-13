import 'package:flutter/material.dart';
import 'package:tdffi/td.dart' as t;
import '../../auth/widget/auth_route_manager.dart';
import '../models/chat.dart';

class ChatHistoryScreen extends StatelessWidget {
  const ChatHistoryScreen({super.key, required this.chat});
  final Chat chat;
  static const String subpath = 'history';
  static const String path = '/chat/history';

  @override
  Widget build(BuildContext context) {
    return AuthRouteManager(
      child: Scaffold(
        appBar: AppBar( 
          //TODO: show Title, Photo, chat type / member count
          title: Text(chat.title),
        ),
      ),
    );
  }
}
