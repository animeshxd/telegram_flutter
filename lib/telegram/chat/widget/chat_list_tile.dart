import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:tdffi/client.dart';
import '../controller/download_profile_photo.dart';
import '../cubit/chat_cubit.dart';
import 'package:tdffi/td.dart' as t;

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
        child: ObxValue(
          (data) => subtitle(data[chat.id]?.last_message),
          state.lastMessages,
        ),
      ),
      trailing: trailing,
    );
  }
  Widget get trailing => Obx(() {
        var count = state.unReadCount[chat.id];
        if (count == null || count == 0) {
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
        return Badge(
          label: Text(count.toString()),
          backgroundColor: Theme.of(context).colorScheme.primary,
        );
      });

  Future<Widget> titleW() async {
    var title = chat.title;
    var icon = switch (chat.type.runtimeType) {
      t.ChatTypeBasicGroup => Icons.group,
      t.ChatTypeSupergroup => chat.type.chatTypeSupergroup!.is_channel
          ? FontAwesomeIcons.bullhorn
          : Icons.group,
      _ => null
    };
    Widget? tailing;

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
        tailing = const Icon(
          Icons.check_circle_outline, //TODO: ADD better
          size: 14,
          color: Colors.green,
        );
      }

      if (user.is_fake || user.is_scam) {
        tailing = Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red),
            borderRadius: const BorderRadius.all(Radius.circular(3)),
          ),
          child: Text(
            user.is_fake ? 'FAKE' : 'SCAM',
            style: const TextStyle(fontSize: 8),
          ),
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
          if (tailing != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
              child: tailing,
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

  Future<t.User> _getUser(int id) async {
    var user = await _tdlib.send<t.User>(t.GetUser(user_id: id));
    state.users[id] = user;
    return user;
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
          future: _getUser(id),
          builder: (context, snapshot) {
            if (snapshot.data?.type.userTypeDeleted != null) {
              return CircleAvatar(
                backgroundColor: color,
                child: const Icon(FontAwesomeIcons.ghost, color: Colors.white),
              );
            }
            return CircleAvatar(backgroundColor: color, child: const Text("🫥"),);
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

  Widget subtitle(t.Message? message) {
    if (message == null) return const SizedBox.shrink();
    var content = message.content;
    String? caption = switch (content.runtimeType) {
      t.MessageAudio => content.messageAudio!.caption.text,
      t.MessageDocument => content.messageDocument!.caption.text,
      t.MessageVideo => content.messageVideo!.caption.text,
      t.MessagePhoto => content.messagePhoto!.caption.text,
      t.MessageText => content.messageText!.text.text,
      t.MessagePoll => content.messagePoll!.poll.question,
      t.MessageSticker => "${content.messageSticker!.sticker.emoji} Sticker",
      t.MessageGame => content.messageGame!.game.short_name,
      t.MessageGameScore => "High Score: ${content.messageGameScore!.score}",
      t.MessageSupergroupChatCreate => "Channel created",
      t.MessageChatChangeTitle =>
        "Channel name was changed to ${content.messageChatChangeTitle!.title}",
      t.MessageAnimatedEmoji => content.messageAnimatedEmoji!.emoji,
      // TODO: show who joined
      t.MessagePinMessage => "{sender_id} has pinned this message",
      t.MessageChatSetMessageAutoDeleteTime => "{sender_id} set messages to "
          "${content.messageChatSetMessageAutoDeleteTime!.message_auto_delete_time} Seconds",
      //TODO: 0 is disabled autodelete
      t.MessageContactRegistered => "{title} has joined Telegram",
      t.MessageChatJoinByLink => "{sender_id} has joined by link",
      t.MessageChatJoinByRequest =>
        "{sender_id}'s join request accepted by admin",
      t.MessageChatAddMembers => "{sender_id} joined chat / added users",
      t.MessageChatDeleteMember => "{sender_id} removed user {user_id}",
      _ => null
    };

    var icon = switch (content.runtimeType) {
      t.MessageAudio => Icons.audio_file,
      t.MessageDocument => Icons.attach_file,
      t.MessagePhoto => Icons.photo,
      t.MessageVideo => Icons.video_file,
      t.MessageCall => Icons.call,
      t.MessageGame || t.MessageGameScore => Icons.games,
      t.MessagePoll => Icons.poll,
      _ => null
    };

    if (icon != null || caption != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
              child: Icon(icon, size: 17),
            ),
          if (caption != null)
            Expanded(child: EllipsisText(caption, removeNewLine: true))
        ],
      );
    }
    return const SizedBox.shrink();
  }
}
