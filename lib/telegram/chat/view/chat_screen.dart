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
    context.read<ChatCubit>().loadChats();
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
    return BlocListener<AuthBloc, AuthState>(
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
                return Text(
                  "Error",
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                );
              }

              if (state is ChatLoaded) {
                var chats = state.chats
                    // .where((element) => element.title.isNotEmpty)
                    .toList();
                chats.sort((a, b) => b.unread_count.compareTo(a.unread_count));
                return ListView.builder(
                  addAutomaticKeepAlives: false,
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    var chat = chats[index];
                    profilePhotoController.downloadFile(chat.photo?.small);
                    return ListTile(
                      //TODO: add better download small photo with retry
                      leading: leading(chat),
                      title: FutureBuilder(
                        initialData: const SizedBox.shrink(),
                        future: titleW(chat),
                        builder: (context, snapshot) => snapshot.data!,
                      ),
                      subtitle: Align(
                        alignment: Alignment.centerLeft,
                        child: Obx(
                          () =>
                              subtitle(state.lastMessages[chat.id]) ??
                              const SizedBox.shrink(),
                        ),
                      ),
                      onTap: () => debugPrint(
                        '${state.lastMessages[chat.id]} \nchat: ${chat.toJsonEncoded()}',
                      ),
                      //TODO: update realtime unread_count
                      trailing: Obx(() {
                        var count = state.unReadCount[chat.id];
                        if (count == null || count == 0) {
                          return const SizedBox.shrink();
                        }
                        return Text(count.toString());
                      }),
                    );
                  },
                );
              }

              return const CircularProgressIndicator();
            },
          ),
        ),
      ),
    );
  }

  Future<Widget?> titleW(t.Chat chat) async {
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
      var user = await tdlib.send<t.User>(t.GetUser(user_id: chat.id));
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
    return null;
  }

  Widget leading(t.Chat chat) {
    String title = chat.title
        .split(" ")
        .where((element) => element.isNotEmpty)
        .take(2)
        .map((e) => e[0])
        .join();
    var photo = chat.photo?.small;
    if (photo == null) {
      return CircleAvatar(child: Text(title));
    }

    Widget? avatar = avatarW(photo.local.path);
    if (avatar != null) return avatar;
    var imageSourceb64 = chat.photo?.minithumbnail?.data;
    if (imageSourceb64 != null) {
      var imageSource = base64.decode(imageSourceb64);
      avatar = CircleAvatar(backgroundImage: MemoryImage(imageSource));
    }

    return ObxValue<RxMap<int, String>>(
      (data) =>
          avatarW(data[photo.id]) ?? avatar ?? CircleAvatar(child: Text(title)),
      profilePhotoController.state,
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

  Widget? subtitle(t.Message? message) {
    if (message == null) return null;
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
      // TODO: show who joined
      t.MessagePinMessage => "has pinned this message",
      t.MessageContactRegistered => "{title} has joined Telegram",
      t.MessageChatJoinByLink => "{someone} has joined by link",
      t.MessageChatJoinByRequest =>
        "{someone}'s join request accepted by admin",
      _ => null
    };

    var icon = switch (content.runtimeType) {
      t.MessageAudio => Icons.audio_file,
      t.MessageDocument => Icons.attach_file,
      t.MessagePhoto => Icons.photo,
      t.MessageVideo => Icons.video_file,
      t.MessageCall => Icons.call,
      t.MessageGame || t.MessageGameScore => Icons.games,
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
              child: Icon(icon, size: 14),
            ),
          if (caption != null)
            Expanded(child: EllipsisText(caption.replaceAll("\n", " ")))
        ],
      );
    }
    return null;
  }
}
