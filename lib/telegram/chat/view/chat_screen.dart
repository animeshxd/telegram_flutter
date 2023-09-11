import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:tdffi/client.dart';
import 'package:tdffi/td.dart' as t;
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
  @override
  void initState() {
    super.initState();
    context.read<ChatCubit>().loadChats();
    tdlib = context.read<TdlibEventController>();
  }

  @override
  void dispose() {
    super.dispose();
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
                    .where((element) => element.title.isNotEmpty)
                    .toList();
                chats.sort((a, b) => b.unread_count.compareTo(a.unread_count));
                return ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    var chat = chats[index];
                    var imageSourceb64 = chat.photo?.minithumbnail?.data;
                    String? title;

                    title = chat.title
                        .split(" ")
                        .where((element) => element.isNotEmpty)
                        .take(2)
                        .map((e) => e[0])
                        .join();

                    Widget avatar = CircleAvatar(
                      child: Text(title),
                    );
                    if (imageSourceb64 != null) {
                      var imageSource = base64.decode(imageSourceb64);
                      avatar = CircleAvatar(
                        backgroundImage: MemoryImage(imageSource),
                      );
                    }

                    return ListTile(
                      leading: avatar, //TODO: download small photo
                      title: EllipsisText(chat.title),
                      subtitle: Align(
                        alignment: Alignment.centerLeft,
                        child: Obx(
                          () =>
                              subtitle(state.lastMessages[chat.id]) ??
                              Container(),
                        ),
                      ),
                      onTap: () => debugPrint(chat.toJsonEncoded()),
                      //TODO: update realtime unread_count
                      trailing: chat.unread_count == 0
                          ? null
                          : Text(chat.unread_count.toString()),
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

  Widget? subtitle(t.Message? message) {
    if (message == null) return null;
    var content = message.content;
    String? caption = switch (content.runtimeType) {
      t.MessageAudio => content.messageAudio!.caption.text,
      t.MessageDocument => content.messageDocument!.caption.text,
      t.MessagePhoto => content.messagePhoto!.caption.text,
      t.MessageText => content.messageText!.text.text,
      t.MessagePoll => content.messagePoll!.poll.question,
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
      t.MessageCall => Icons.call,
      _ => null
    };

    if (icon != null || caption != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
              child: Icon(icon),
            ),
          if (caption != null)
            Expanded(child: EllipsisText(caption.replaceAll("\n", " ")))
        ],
      );
    }
    return null;
  }
}
