import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tdffi/client.dart';
import 'package:tdffi/td.dart' as t;
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/chat_bloc.dart';

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
    context.read<ChatBloc>().add(LoadChats());
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
          child: BlocBuilder<ChatBloc, ChatState>(
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
                      leading: avatar,
                      title: Text(chat.title),
                      onTap: () => debugPrint(chat.toJsonEncoded()),
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
}
