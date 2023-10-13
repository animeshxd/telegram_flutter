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
import 'chat_avatar.dart';
import 'chat_draft_message.dart';
import 'chat_label.dart';
import 'chat_mentioned_badge.dart';
import 'chat_message.dart';
import 'chat_reaction_badge.dart';
import 'ellipsis_text.dart';

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
            title: titleW(chat, user),
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
            onTap: () => context.push(ChatHistoryScreen.path, extra: chat),
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
            backgroundColor: Theme.of(context).colorScheme.primary,
          );
        }),
      ],
    );
  }

  Widget titleW(Chat chat, t.User? user) {
    var title = chat.title;
    // var icon = switch (chat.type.runtimeType) {
    //   t.ChatTypeBasicGroup => FontAwesomeIcons.userGroup,
    //   t.ChatTypeSupergroup => chat.type.chatTypeSupergroup!.is_channel
    //       ? FontAwesomeIcons.bullhorn
    //       : FontAwesomeIcons.userGroup,
    //   _ => null
    // };
    Widget? label;

    if (user != null) {
      if (user.type is t.UserTypeDeleted) {
        title = 'Deleted Account';
      }
      // if (user.type is t.UserTypeBot) {
      //   icon = FontAwesomeIcons.robot;
      // }

      if (user.is_verified) {
        label = Icon(
          Icons.verified,
          size: 14,
          color: Theme.of(context).colorScheme.primary,
        );
      }
      if (user.is_fake || user.is_scam) {
        label = ChatLabel(
          label: user.is_fake ? "FAKE" : "SCAM",
        );
      }
    }

    if (/*icon != null ||*/ title.isNotEmpty) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // if (icon != null)
          //   Padding(
          //     padding: const EdgeInsets.fromLTRB(0, 0, 5, 0),
          //     child: Icon(icon, size: 10),
          //   ),
          if (title.isNotEmpty)
            Flexible(
              child: EllipsisText(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          if (label != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
              child: label,
            ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}
