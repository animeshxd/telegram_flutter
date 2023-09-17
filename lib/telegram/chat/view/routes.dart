import 'package:go_router/go_router.dart';
import 'package:tdffi/td.dart';
import 'package:telegram_flutter/telegram/auth/bloc/auth_bloc.dart';
import 'package:telegram_flutter/telegram/chat/view/chat_screen.dart';

var chatRoute = GoRoute(
  path: ChatScreen.path,
  builder: (context, state) {
    return ChatScreen(
      chatListType: switch (state.uri.fragment) {
        "archive" => ChatListArchive(),
        _ => ChatListMain()
      },
      state: state.extra as AuthStateCurrentAccountReady?,
    );
  },
);
