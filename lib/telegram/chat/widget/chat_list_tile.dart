import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tdffi/client.dart';
import 'package:tdffi/td.dart' as t;

import '../../profile/services/download_profile_photo.dart';
import '../cubit/chat_cubit.dart';
import '../models/chat.dart';
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
  late final DownloadProfilePhoto _downloadProfilePhoto;

  @override
  void initState() {
    super.initState();
    _tdlib = context.read();
    _downloadProfilePhoto = context.read();
  }

  Chat get chat => widget.chat;
  ChatLoaded get state => widget.state;

  @override
  Widget build(context) {
    return ListTile(
      //TODO: add better download small photo with retry
      leading: leading(),
      title: FutureBuilder(
        initialData: const SizedBox.shrink(),
        future: titleW(),
        builder: (_, snapshot) => snapshot.data!,
      ),
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
      onTap: _debug,
    );
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

  Future<Widget> titleW() async {
    var title = chat.title;
    var icon = switch (chat.type.runtimeType) {
      t.ChatTypeBasicGroup => Icons.group,
      t.ChatTypeSupergroup => chat.type.chatTypeSupergroup!.is_channel
          ? FontAwesomeIcons.bullhorn
          : Icons.group,
      _ => null
    };
    Widget? label;

    //TODO: also check if current logged in user is bot or not
    if (chat.type is t.ChatTypePrivate) {
      var user = state.users[chat.type.chatTypePrivate!.user_id];
      user ??= await _tdlib.send<t.User>(t.GetUser(user_id: chat.id));
      // TODO: Fix for bot

      if (user.type is t.UserTypeDeleted) {
        title = 'Deleted Account';
      }
      if (user.type is t.UserTypeBot) {
        icon = FontAwesomeIcons.robot;
      }

      if (user.is_verified) {
        label = const Icon(
          Icons.check_circle_outline, //TODO: ADD better
          size: 14,
          color: Colors.green,
        );
      }
      if (user.is_fake || user.is_scam) {
        label = ChatLabel(
          label: user.is_fake ? "FAKE" : "SCAM",
        );
      }
    }

    if (icon != null || title.isNotEmpty) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
              child: Icon(icon, size: 14),
            ),
          if (title.isNotEmpty) Flexible(child: EllipsisText(title)),
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

  Widget leading() {
    var photo = chat.photo?.small;
    if (photo == null) {
      return Obx(() {
        var user = state.users[chat.type.chatTypePrivate?.user_id ?? 0];
        return _getColorAvatar(chat, chat.title, user);
      });
    }

    Widget? avatar = avatarW(photo.local.path);
    if (avatar != null) return avatar;
    var imageSourceb64 = chat.photo?.minithumbnail?.data;
    if (imageSourceb64 != null) {
      var imageSource = base64.decode(imageSourceb64);
      avatar = CircleAvatar(backgroundImage: MemoryImage(imageSource));
    }

    return Obx(
      () {
        var data = _downloadProfilePhoto.state[photo.id];
        var user = state.users[chat.type.chatTypePrivate?.user_id ?? 0];
        return avatarW(data) ??
            avatar ??
            _getColorAvatar(chat, chat.title, user);
      },
    );
  }

  Widget _getColorAvatar(Chat chat, String title, t.User? user) {
    List<Color> colors = const [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.purple,
      Colors.indigo,
      Colors.deepOrange,
      Colors.grey,
      Colors.deepPurpleAccent
    ];
    var id = chat.type.chatTypeBasicGroup?.basic_group_id ??
        chat.type.chatTypePrivate?.user_id ??
        chat.type.chatTypeSecret?.secret_chat_id ??
        chat.type.chatTypeSecret?.user_id ??
        chat.type.chatTypeSupergroup?.supergroup_id;
    var color = colors[[0, 7, 4, 1, 6, 3, 5][(id! % 7)]];
    var shortTitle = title
        .split(" ")
        .where((element) => element.isNotEmpty)
        .take(2)
        .map((e) => e[0])
        .join();
    if (shortTitle.isEmpty) {
      if (user == null) {
        return FutureBuilder(
          future: state.getUser(id, _tdlib),
          builder: (context, snapshot) {
            if (snapshot.data?.type.userTypeDeleted != null) {
              return CircleAvatar(
                backgroundColor: color,
                child: const Icon(FontAwesomeIcons.ghost, color: Colors.white),
              );
            }
            return CircleAvatar(
              backgroundColor: color,
              child: const Text("🫥"),
            );
          },
        );
      }

      if (user.type.userTypeDeleted != null) {
        return CircleAvatar(
          backgroundColor: color,
          child: const Icon(FontAwesomeIcons.ghost, color: Colors.white),
        );
      }
    }

    return CircleAvatar(
      backgroundColor: color,
      child: Text(
        shortTitle,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget? avatarW(
    String? path,
  ) {
    // debugPrint(path);
    if (path == null) return null;
    if (path.isEmpty) return null;
    var file = File(path);
    if (!file.existsSync()) return null;
    return CircleAvatar(backgroundImage: FileImage(file));
  }
}
