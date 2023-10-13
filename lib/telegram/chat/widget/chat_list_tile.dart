import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:tdffi/client.dart';
import 'package:tdffi/td.dart' as t;
import '../view/chat_history_screen.dart';

import '../cubit/chat_cubit.dart';
import '../models/chat.dart';
import 'chat_title.dart';
import 'chat_avatar.dart';
import 'chat_draft_message.dart';
import 'chat_mentioned_badge.dart';
import 'chat_message.dart';
import 'chat_reaction_badge.dart';

class ChatListTile extends StatefulWidget {
  const ChatListTile({
    super.key,
    required this.chat,
    required this.state,
    required this.chatListType,
  });
  final Chat chat;
  final ChatLoaded state;
  final t.ChatList chatListType;

  @override
  State<ChatListTile> createState() => _ChatListTileState();
}

class _ChatListTileState extends State<ChatListTile> {
  late final TdlibEventController _tdlib;

  @override
  void initState() {
    super.initState();
    _tdlib = context.read();
  }

  Chat get chat => widget.chat;
  ChatLoaded get state => widget.state;

  @override
  Widget build(context) {
    return FutureBuilder<t.User?>(
        future: chat.isPrivate
            ? state.getUser(chat.type.chatTypePrivate!.user_id, _tdlib)
            : null,
        builder: (context, snapshot) {
          var user = snapshot.data;
          return ListTile(
            //TODO: add better download small photo with retry
            leading: ChatAvatar(chat: chat, user: user),
            title: ChatTitle(chat: chat, user: user),
            subtitle: Align(
              alignment: Alignment.centerLeft,
              child: Obx(() {
                var message = chat.lastMessage;
                var draftMessage = chat.draftMessage;
                if (draftMessage != null) {
                  return ChatDraftMessage(draftMessage: draftMessage);
                }
                if (message == null) return const SizedBox.shrink();
                return ChatMessage(
                  chat: chat,
                  message: message,
                  state: state,
                );
              }),
            ),
            trailing: trailing,
            onTap: () => context.push(ChatHistoryScreen.path,
                extra: {'chat': chat, 'user': user}),
          );
        });
  }

  void _debug() async {
    //unstaged body
  }

  String formatDateOfLastMessage(int? unixTime) {
    // TODO: may seperate it
    if (unixTime == null || unixTime == 0) return '';
    var dateTime = DateTime.fromMillisecondsSinceEpoch(unixTime * 1000);
    var dateNow = DateTime.now();
    var timeDiff = dateTime.difference(dateNow);
    if (timeDiff.inDays < -6) {
      return DateFormat("d/MM/yy").format(dateTime);
    } else if (timeDiff.inDays == 0) {
      return DateFormat.jm().format(dateTime);
    } else {
      return DateFormat("EEE").format(dateTime);
    }
  }

  Widget get trailing {
    var lastMessage = chat.lastMessage;
    String dateFormatOfLastMessage = '';

    if (lastMessage != null) {
      dateFormatOfLastMessage = formatDateOfLastMessage(
        lastMessage.edit_date != 0 ? lastMessage.edit_date : lastMessage.date,
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (dateFormatOfLastMessage.isNotEmpty) Text(dateFormatOfLastMessage),
        Obx(() {
          if (chat.unreadMentionCount.value > 0) {
            return const ChatMentionedBadge();
          }

          if (chat.unreadReactionCount.value > 0) {
            return const ChatReactionBadge();
          }
          var count = chat.unreadMessageCount.value;
          if (count == 0) {
            var isPinned = chat.positions
                .where((element) =>
                    element.list.runtimeType == widget.chatListType.runtimeType)
                .any((element) => element.is_pinned);
            if (isPinned) {
              return Transform.rotate(
                angle: 1,
                child: const Icon(
                  Icons.push_pin,
                  size: 16,
                ),
              );
            }
            return const SizedBox.shrink();
          }
          return Badge.count(
            count: count,
            backgroundColor: Theme.of(context).colorScheme.secondary,
          );
        }),
      ],
    );
  }
}
