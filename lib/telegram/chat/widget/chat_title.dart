import 'package:flutter/material.dart';
import 'package:tdffi/td.dart' as t;

import '../models/chat.dart';
import 'chat_label.dart';
import 'ellipsis_text.dart';

class ChatTitle extends StatefulWidget {
  const ChatTitle({super.key, required this.chat, this.user});
  final Chat chat;
  final t.User? user;
  @override
  State<ChatTitle> createState() => _ChatTitleState();
}

class _ChatTitleState extends State<ChatTitle> {
  @override
  Widget build(BuildContext context) {
    return titleW(widget.chat, widget.user);
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
                style: const TextStyle(fontWeight: FontWeight.w500),
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
