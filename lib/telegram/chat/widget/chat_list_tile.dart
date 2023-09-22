import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:humanizer/humanizer.dart';
import 'package:tdffi/client.dart';
import 'package:tdffi/td.dart' as t;

import '../../../const/regexs.dart';
import '../../../extensions/extensions.dart';
import '../controller/download_profile_photo.dart';
import '../cubit/chat_cubit.dart';
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
  late TextStyle _textStyleBodySmall;

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
    _textStyleBodySmall = Theme.of(context).textTheme.bodySmall!;
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
          (data) => FutureBuilder(
            future: subtitle(data[chat.id]?.last_message),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.hasError) {
                return const SizedBox.shrink();
              }
              return snapshot.data!;
            },
          ),
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
    if (state.users[id] != null) state.users[id];
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

  String _getDocumentCaption(t.MessageContent content) {
    if (content is! t.MessageDocument) return '';

    var caption = content.caption.text;
    if (caption.isEmpty) caption = content.document.file_name;

    return caption;
  }

  String _getMessageChatSetMessageAutoDeleteTimeCaption(
      t.MessageContent content) {
    if (content is! t.MessageChatSetMessageAutoDeleteTime) return '';
    var time = Duration(seconds: content.message_auto_delete_time);
    if (time.inSeconds == 0) {
      return "disabled the auto-delete timer";
    } else {
      return "set messages to auto-delete in ${time.toApproximateTime(isRelativeToNow: false)}";
    }
  }

  Future<Widget> subtitle(t.Message? message) async {
    //TODO: Show album caption, resolve album
    //TODO: Separator Caption only
    //TODO: Show text format based on FormattedText
    //TODO: Show who pinned what message/type of content
    if (message == null) return const SizedBox.shrink();
    var content = message.content;

    String senderName = '';
    var isChatActions = switch (content.runtimeType) {
      t.MessagePinMessage ||
      t.MessageContactRegistered ||
      t.MessageGameScore ||
      t.MessageChatJoinByLink ||
      t.MessageChatJoinByRequest ||
      t.MessageChatAddMembers ||
      t.MessageChatDeleteMember ||
      t.MessageGame ||
      t.MessageGameScore ||
      t.MessageChatChangeTitle ||
      t.MessageChatSetMessageAutoDeleteTime =>
        true,
      _ => false
    };
    var isChannel = (chat.type.chatTypeSupergroup?.is_channel ?? false);
    var isGroup = !isChannel &&
        chat.type.chatTypePrivate == null &&
        chat.type.chatTypeSecret == null;
    var isPrivate = (chat.type.chatTypePrivate != null);
    var senderRequired =
        !message.is_outgoing && ((isPrivate && isChatActions) || isGroup);

    if (senderRequired) {
      try {
        var senderUserId = message.sender_id.messageSenderUser?.user_id;
        var senderChatId = message.sender_id.messageSenderChat?.chat_id;
        var senderUser =
            senderUserId != null ? await _getUser(senderUserId) : null;
        var senderChat = senderChatId != null
            ? await _tdlib.send<t.Chat>(t.GetChat(chat_id: senderChatId))
            : null;

        senderName = senderUser?.fullName ?? senderChat?.title ?? '';
        senderName = senderName.replaceAll(spaceLikeCharacters, ' ');
        senderName = senderName.replaceAll(RegExp(r'\s{2,}'), '');
      } on TelegramError catch (e) {
        if (e.code != 404) rethrow;
      }
    }
    if (message.is_outgoing && isChatActions) senderName = 'You';

    String? caption = switch (content.runtimeType) {
      t.MessageAudio => content.messageAudio!.caption.text,
      t.MessageDocument => _getDocumentCaption(content),
      t.MessageVideo => content.messageVideo!.caption.text,
      t.MessagePhoto => content.messagePhoto!.caption.text,
      t.MessageText => content.messageText!.text.text,
      t.MessagePoll => content.messagePoll!.poll.question,
      t.MessageSticker => "${content.messageSticker!.sticker.emoji} Sticker",
      t.MessageGame => content.messageGame!.game.short_name,
      t.MessageGameScore => "scored ${content.messageGameScore!.score}",
      t.MessageSupergroupChatCreate => "Channel created",
      t.MessageChatChangeTitle => content.messageChatChangeTitle!.title,
      t.MessageAnimatedEmoji => content.messageAnimatedEmoji!.emoji,
      t.MessagePinMessage => "pinned a message",
      t.MessageChatSetMessageAutoDeleteTime =>
        _getMessageChatSetMessageAutoDeleteTimeCaption(content),
      t.MessageContactRegistered => "joined Telegram",
      t.MessageChatJoinByLink => "joined the chat via invite link",
      t.MessageChatJoinByRequest => "'s join request accepted by admin",
      t.MessageChatAddMembers => "joined chat / added users",
      t.MessageChatDeleteMember => "removed user {user_id}",
      _ => null
    };

    if (content is t.MessageChatAddMembers) {
      var id = message.sender_id.messageSenderUser?.user_id ??
          message.sender_id.messageSenderChat?.chat_id;
      if (content.member_user_ids.any((element) => element == id)) {
        caption = "joined the group";
      } else {
        var users = await Future.wait(
          content.member_user_ids.map((id) => _getUser(id)),
        );
        caption = "added ${users.map((e) => e.fullName).join(', ')}";
      }
    }
    if (content is t.MessageChatDeleteMember) {
      var id = message.sender_id.messageSenderUser?.user_id ??
          message.sender_id.messageSenderChat?.chat_id;
      if (content.user_id == id) {
        caption = "left the group";
      } else {
        var user = await _getUser(content.user_id);
        caption = "removed ${user.fullName}";
      }
    }

    if (content is t.MessageChatChangeTitle) {
      if (isChannel) {
        caption = "Channel name was changed to «$caption»";
      } else {
        caption = "changed group name to «$caption»";
      }
    }

    if (content is t.MessageGameScore) {
      try {
        var message = await _tdlib.send<t.Message>(
          t.GetMessage(chat_id: chat.id, message_id: content.game_message_id),
        );
        var title = message.content.messageGame!.game.title;
        caption = '${caption!} in $title';
      } on TelegramError catch (e) {
        if (e.code != 404) {
          rethrow;
        }
      }
    }

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
            Expanded(
              child: RichText(
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: _textStyleBodySmall,
                  children: [
                    if (senderName.isNotEmpty)
                      TextSpan(
                        text: senderName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    if (senderName.isNotEmpty)
                      TextSpan(text: isChatActions ? ' ' : " : "),
                    TextSpan(text: caption.trim().replaceAll('\n', '')),
                  ],
                ),
              ),
            )
        ],
      );
    }
    return const SizedBox.shrink();
  }
}
