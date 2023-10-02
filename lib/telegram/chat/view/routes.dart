import 'package:go_router/go_router.dart';
import 'package:tdffi/td.dart';
import '../../auth/bloc/auth_bloc.dart';
import 'chat_list_screen.dart';

var chatRoute = GoRoute(
  path: ChatListScreen.path,
  builder: (context, state) {
    return ChatListScreen(
      chatListType: switch (state.uri.fragment) {
        "archive" => ChatListArchive(),
        _ => ChatListMain()
      },
      state: state.extra as AuthStateCurrentAccountReady?,
    );
  },
);
