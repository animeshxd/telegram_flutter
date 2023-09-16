import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:tdffi/client.dart';
import 'package:tdffi/td.dart' as t;
import '../controller/download_profile_photo.dart';
import '../cubit/chat_cubit.dart';
import '../widget/ellipsis_text.dart';
import '../../auth/bloc/auth_bloc.dart';

class ChatScreen extends StatefulWidget {
  final AuthStateCurrentAccountReady? state;
  const ChatScreen({super.key, this.state});
  static const path = '/chat';
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final TdlibEventController tdlib;
  late final DownloadProfilePhoto profilePhotoController;
  @override
  void initState() {
    super.initState();
    context.read<ChatCubit>().loadChats(t.ChatListArchive());
    tdlib = context.read<TdlibEventController>();
    profilePhotoController = DownloadProfilePhoto(tdlib);
    // TODO: move to main.dart
    profilePhotoController.loadExisting();
  }

  @override
  void dispose() {
    super.dispose();
    profilePhotoController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: profilePhotoController,
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (previous, current) =>
            current is! AuthStateCurrentAccountReady,
        listener: (context, state) => state.doRoute(context),
        child: Scaffold(
          appBar: AppBar(title: const Text("Telegram")),
          drawer: Drawer(
            child: ListView(
              children: const [DrawerHeader(child: Text(''))],
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
                    var chats = state.chats.entries
                        .where((e) => _whereChatIsNotInteracted(e.value, state))
                        .map((e) => e.value)
                        .toList();
                    _sortChatsByPosition(chats);
                    return ListView.builder(
                      addAutomaticKeepAlives: false,
                      itemCount: chats.length,
                      itemBuilder: (context, index) {
                        var chat = chats[index];
                        profilePhotoController.downloadFile(chat.photo?.small);
                        return ChatListTile(chat: chat, state: state);
                      },
                    );
                  });
                }

                return const CircularProgressIndicator();
              },
            ),
          ),
        ),
      ),
    );
  }

  bool _whereChatIsNotInteracted(Chat c, ChatLoaded state) {
    var type = c.type;
    var id = type.chatTypeBasicGroup?.basic_group_id ??
        type.chatTypePrivate?.user_id ??
        type.chatTypeSecret?.secret_chat_id ??
        type.chatTypeSupergroup?.supergroup_id;
    if (id == null) return false;
    return !state.ignoredChats.contains(id);
  }

  void _sortChatsByPosition(List<Chat> chats) {
    chats.sort((a, b) {
      var b0 = b.positions
              .where((position) => position.list.chatListMain != null)
              .map((e) => e.is_pinned ? -1 : int.parse(e.order))
              .firstOrNull ??
          0;
      var a0 = a.positions
              .where((position) => position.list.chatListMain != null)
              .map((e) => e.is_pinned ? -1 : int.parse(e.order))
              .firstOrNull ??
          0;
      if (b0 == -1) return 1;
      if (a0 == -1) return -1;

      return b0.compareTo(a0);
    });
  }
}

class ChatListTile extends StatefulWidget {
  const ChatListTile({
    super.key,
    required this.chat,
    required this.state,
  });
  final Chat chat;
  final ChatLoaded state;

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
      trailing: Obx(() {
        //TODO: update realtime unread_count
        var count = state.unReadCount[chat.id];
        if (count == null || count == 0) {
          return const SizedBox.shrink();
        }
        return Text(count.toString());
      }),
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
        return _getColorAvater(chat, chat.title, user);
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
            _getColorAvater(chat, chat.title, user);
      },
    );
  }

  Widget _getColorAvater(Chat chat, String title, t.User? user) {
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
    var id = int.parse(chat.id.toString().replaceAll("-100", ""));
    var color = colors[[0, 7, 4, 1, 6, 3, 5][(id % 7)]];
    var shortTitle = title
        .split(" ")
        .where((element) => element.isNotEmpty)
        .take(2)
        .map((e) => e[0])
        .join();
    if (shortTitle.isEmpty && user != null) {
      //TODO: return furure builder
      return CircleAvatar(
        backgroundColor: color,
        child: const Icon(FontAwesomeIcons.ghost, color: Colors.white),
      );
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
            Expanded(child: EllipsisText(caption.replaceAll("\n", " ")))
        ],
      );
    }
    return const SizedBox.shrink();
  }
}
