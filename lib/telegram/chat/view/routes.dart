import 'package:go_router/go_router.dart';
import 'package:tdffi/td.dart';
import 'chat_history_screen.dart';
import '../../auth/bloc/auth_bloc.dart';
import 'chat_list_screen.dart';
import '../models/chat.dart' as m;

var chatRoute = GoRoute(
  path: '/chat',
  redirect: (context, state) =>
      state.fullPath == '/chat' ? ChatListScreen.path : null,
  routes: [
    GoRoute(
      path: ChatListScreen.subpath,
      builder: (context, state) {
        return ChatListScreen(
          chatListType: switch (state.uri.fragment) {
            "archive" => ChatListArchive(),
            _ => ChatListMain()
          },
          state: state.extra as AuthStateCurrentAccountReady?,
        );
      },
    ),
    GoRoute(
      path: ChatHistoryScreen.subpath,
      builder: (context, state) =>
          ChatHistoryScreen(chat: state.extra as m.Chat),
    )
  ],
);
