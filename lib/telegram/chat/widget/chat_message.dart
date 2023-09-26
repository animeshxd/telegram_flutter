import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:humanizer/humanizer.dart';
import 'package:tdffi/client.dart';
import 'package:tdffi/td.dart' as t;
import '../../../const/regexs.dart';
import '../cubit/chat_cubit.dart';
import '../models/chat.dart';
import '../../../extensions/extensions.dart';

class ChatMessage extends StatefulWidget {
  const ChatMessage({
    super.key,
    required this.chat,
    required this.message,
    required this.state,
  });
  final Chat chat;
  final ChatLoaded state;
  final t.Message message;

  @override
  State<ChatMessage> createState() => _ChatMessageState();
}

class _ChatMessageState extends State<ChatMessage> {
  late final TdlibEventController _tdlib;

  late TextStyle _textStyleBodySmall;

  @override
  void initState() {
    super.initState();
    _tdlib = context.read();
  }

  ChatLoaded get state => widget.state;
  Chat get chat => widget.chat;

  @override
  Widget build(BuildContext context) {
    _textStyleBodySmall = Theme.of(context).textTheme.bodySmall!;

    return FutureBuilder(
      future: subtitle(widget.message),
      initialData: const SizedBox.shrink(),
      builder: (context, snapshot) {
        return snapshot.data!;
      },
    );
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

  Future<String> _getMessageChatAddMembers(t.Message message) async {
    var content = message.content;
    if (content is! t.MessageChatAddMembers) return '';

    var id = message.sender_id.messageSenderUser?.user_id ??
        message.sender_id.messageSenderChat?.chat_id;
    if (content.member_user_ids.any((element) => element == id)) {
      return "joined the group";
    } else {
      var users = await Future.wait(
        content.member_user_ids.map((id) => state.getUser(id, _tdlib)),
      );
      return "added ${users.map((e) => e.fullName).join(', ')}";
    }
  }

  Future<String> _getMessageChatDeleteMember(t.Message message) async {
    var content = message.content;
    if (content is! t.MessageChatDeleteMember) return '';
    var id = message.sender_id.messageSenderUser?.user_id ??
        message.sender_id.messageSenderChat?.chat_id;
    if (content.user_id == id) {
      return "left the group";
    } else {
      var user = await state.getUser(content.user_id, _tdlib);
      return "removed ${user.fullName}";
    }
  }

  Future<String> _getMessageChatChangeTitle(
      t.MessageContent content, Chat chat) async {
    if (content is! t.MessageChatChangeTitle) return '';
    var title = content.title;
    if (chat.isChannel) {
      return "Channel name was changed to «$title»";
    } else {
      return "changed group name to «$title»";
    }
  }

  Future<String> _getMessageGameScore(t.MessageContent content) async {
    if (content is! t.MessageGameScore) return '';
    var score = content.score;

    try {
      var message = await _tdlib.send<t.Message>(
        t.GetMessage(chat_id: chat.id, message_id: content.game_message_id),
      );
      var title = message.content.messageGame!.game.title;
      return 'scored $score in $title';
    } on TelegramError catch (e) {
      if (e.code == 404) {
        return 'scored $score';
      }
      rethrow;
    }
  }

  Future<String> _getCaptionText(t.Message message, Chat chat) async {
    var content = message.content;
    return switch (content.runtimeType) {
      t.MessageAudio => content.messageAudio!.caption.text,
      t.MessageDocument => _getDocumentCaption(content),
      t.MessageVideo => content.messageVideo!.caption.text,
      t.MessagePhoto => content.messagePhoto!.caption.text,
      t.MessageText => content.messageText!.text.text,
      t.MessagePoll => content.messagePoll!.poll.question,
      t.MessageSticker => "${content.messageSticker!.sticker.emoji} Sticker",
      t.MessageGame => '🎮 ${content.messageGame!.game.short_name}',
      t.MessageGameScore => await _getMessageGameScore(content),
      t.MessageSupergroupChatCreate => "Channel created",
      t.MessageChatChangeTitle =>
        await _getMessageChatChangeTitle(content, chat),
      t.MessageAnimatedEmoji => content.messageAnimatedEmoji!.emoji,
      t.MessagePinMessage => "pinned a message",
      t.MessageChatSetMessageAutoDeleteTime =>
        _getMessageChatSetMessageAutoDeleteTimeCaption(content),
      t.MessageContactRegistered => "joined Telegram",
      t.MessageChatJoinByLink => "joined the chat via invite link",
      t.MessageChatJoinByRequest => "'s join request accepted by admin",
      t.MessageChatAddMembers => await _getMessageChatAddMembers(message),
      t.MessageChatDeleteMember => await _getMessageChatDeleteMember(message),
      _ => ''
    };
  }

  Future<Widget> subtitle(t.Message? message) async {
    //TODO: Show album caption, resolve album
    //TODO: Separator Caption only
    //TODO: Show text format based on FormattedText
    //TODO: Show who pinned what message/type of content
    if (message == null) return const SizedBox.shrink();
    var content = message.content;

    String senderName = '';
    var isChatActions = content.isChatActions;
    var isGroup = chat.isGroup;
    var isPrivate = chat.isPrivate;
    var senderRequired =
        !message.is_outgoing && ((isPrivate && isChatActions) || isGroup);

    if (senderRequired) {
      try {
        var senderUserId = message.sender_id.messageSenderUser?.user_id;
        var senderChatId = message.sender_id.messageSenderChat?.chat_id;
        var senderUser = senderUserId != null
            ? await state.getUser(senderUserId, _tdlib)
            : null;
        var senderChat = senderChatId != null
            ? await state.getChat(senderChatId, _tdlib)
            : null;
        var title =
            senderUser?.type is t.UserTypeDeleted ? 'Deleted Account' : null;
        senderName = title ?? senderUser?.fullName ?? senderChat?.title ?? '';
        senderName = senderName.replaceAll(spaceLikeCharacters, ' ');
        senderName = senderName.replaceAll(RegExp(r'\s{2,}'), '');
      } on TelegramError catch (e) {
        if (e.code != 404) rethrow;
      }
    }
    if (message.is_outgoing && isChatActions) senderName = 'You';

    String caption = await _getCaptionText(message, chat);

    var icon = switch (content.runtimeType) {
      t.MessageAudio => Icons.audio_file,
      t.MessageDocument => Icons.attach_file,
      t.MessagePhoto => Icons.photo,
      t.MessageVideo => Icons.video_file,
      t.MessageCall => Icons.call,
      t.MessageGameScore => Icons.games,
      t.MessagePoll => Icons.poll,
      _ => null
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
            child: Icon(icon, size: 17),
          ),
        Expanded(
          child: RichText(
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: _textStyleBodySmall,
              children: [
                if (senderName.isNotEmpty) TextSpan(text: senderName),
                if (senderName.isNotEmpty)
                  TextSpan(text: isChatActions ? ' ' : ": "),
                TextSpan(text: caption.trim().replaceAll('\n', '')),
              ],
            ),
          ),
        )
      ],
    );
  }
}
