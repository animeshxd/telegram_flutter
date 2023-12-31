import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:tdffi/client.dart';
import 'package:tdffi/td.dart' as t;
import '../widget/my_accounts_drawer_header.dart';

import '../../auth/widget/auth_route_manager.dart';
import '../models/chat.dart';
import '../widget/chat_list_tile.dart';
import '../../profile/services/download_profile_photo.dart';
import '../cubit/chat_cubit.dart';
import '../../auth/bloc/auth_bloc.dart';

class ChatListScreen extends StatefulWidget {
  final AuthStateCurrentAccountReady? state;
  const ChatListScreen({super.key, this.state, required this.chatListType});
  static const path = '/chat/list';
  static const subpath = 'list';
  final t.ChatList chatListType;
  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late final Tdlib tdlib;
  late final DownloadProfilePhoto profilePhotoController;
  t.ChatList get chatListType => widget.chatListType;
  @override
  void initState() {
    super.initState();
    context.read<ChatCubit>().loadChats(chatListType);
    tdlib = context.read<Tdlib>();
    profilePhotoController = context.read();
    profilePhotoController.loadExisting();
  }

  t.User get me => widget.state!.user.value;

  @override
  Widget build(BuildContext context) {
    return AuthRouteManager(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Telegram"),
          leading: context.canPop()
              ? IconButton(
                  onPressed: () => Navigator.maybeOf(context)?.maybePop(),
                  icon: Icon(Icons.adaptive.arrow_back),
                )
              : null,
        ),
        drawer: Drawer(
          child: ListView(
            children: [MyAccountsDrawerHeader(user: widget.state!.user)],
          ),
        ),
        body: Center(
          child: BlocBuilder<ChatCubit, ChatState>(
            builder: (context, state) {
              if (state is ChatLoadedFailed) {
                return ErrorWidget.withDetails(message: "ChatLoadedFailed");
              }

              if (state is ChatLoaded) {
                // .where((element) => element.title.isNotEmpty)
                // chats.sort((a, b) => b.unread_count.compareTo(a.unread_count));

                return Obx(() {
                  var ignoredChats = state.ignoredChats;
                  var chats = state.chats.entries
                      .where((e) =>
                          _whereChatIsNotInteracted(e.value, ignoredChats))
                      .where(_whereChatHasCurrentChatListType)
                      .where(_whereChatIsNotMe)
                      .map((e) => e.value)
                      .toList();
                  _sortChatsByPosition(chats);
                  return ListView.builder(
                    addAutomaticKeepAlives: false,
                    itemCount: chats.length,
                    itemBuilder: (context, index) {
                      var chat = chats[index];
                      profilePhotoController.downloadFile(chat.photo?.small);
                      return ChatListTile(
                        chat: chat,
                        state: state,
                        chatListType: chatListType,
                      );
                    },
                  );
                });
              }

              return const CircularProgressIndicator();
            },
          ),
        ),
      ),
    );
  }

  bool _whereChatIsNotMe(MapEntry<int, Chat> e) => e.key != me.id;

  bool _whereChatHasCurrentChatListType(MapEntry<int, Chat> e) {
    return e.value.positions
        .any((element) => element.list.runtimeType == chatListType.runtimeType);
  }

  bool _whereChatIsNotInteracted(Chat c, Iterable<int> ignoredChats) {
    var type = c.type;
    var id = type.chatTypeBasicGroup?.basic_group_id ??
        type.chatTypePrivate?.user_id ??
        type.chatTypeSecret?.secret_chat_id ??
        type.chatTypeSupergroup?.supergroup_id;
    if (id == null) return false;
    return !ignoredChats.contains(id);
  }

  void _sortChatsByPosition(List<Chat> chats) {
    chats.sort((a, b) {
      var b0 = b.positions
          .where((p) => p.list.runtimeType == chatListType.runtimeType);

      var a0 = a.positions
          .where((p) => p.list.runtimeType == chatListType.runtimeType);

      var b1 = b0.map((e) => e.order).map(int.parse).firstOrNull ?? 0;
      var a1 = a0.map((e) => e.order).map(int.parse).firstOrNull ?? 0;

      var bIsPinned = b0.any((p) => p.is_pinned);
      var aIsPinned = a0.any((p) => p.is_pinned);

      if (bIsPinned && aIsPinned) return b1.compareTo(a1);
      if (bIsPinned) return 1;
      if (aIsPinned) return -1;

      return b1.compareTo(a1);
    });
  }
}
