import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:tdffi/td.dart' as t;

import '../../profile/services/download_profile_photo.dart';
import '../models/chat.dart';
import '../../../extensions/extensions.dart';

class ChatColorAvatar extends StatelessWidget {
  const ChatColorAvatar({super.key, required this.id, this.child});
  final int id;
  final Widget? child;

  final List<Color> colors = const [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.indigo,
    Colors.deepOrange,
    Colors.grey,
    Colors.deepPurpleAccent
  ];
  Color get color => colors[[0, 7, 4, 1, 6, 3, 5][(id % 7)]];

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(backgroundColor: color, child: child);
  }
}

class ChatAvatar extends StatefulWidget {
  final Chat? chat;
  final t.User? user;
  const ChatAvatar({
    super.key,
    required this.chat,
    this.user,
  }) : assert(chat != null || user != null, "both chat and user can't be null");

  @override
  State<ChatAvatar> createState() => _ChatAvatarState();
}

class _ChatAvatarState extends State<ChatAvatar> {
  late final DownloadProfilePhoto _downloadProfilePhoto;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _downloadProfilePhoto = context.read();
  }

  @override
  Widget build(BuildContext context) {
    return avatar(widget.chat, widget.user);
  }

  Widget avatar(Chat? chat, t.User? user) {
    assert(chat != null || user != null, "both chat and user can't be null");
    var peerId = chat?.type.chatTypeBasicGroup?.basic_group_id ??
        chat?.type.chatTypePrivate?.user_id ??
        chat?.type.chatTypeSecret?.secret_chat_id ??
        chat?.type.chatTypeSecret?.user_id ??
        chat?.type.chatTypeSupergroup?.supergroup_id ??
        user?.id ??
        0;
    var shortTitle = (chat?.title ?? user?.fullName ?? '')
        .split(" ")
        .where((element) => element.isNotEmpty)
        .take(2)
        .map((e) => e[0])
        .join();
    var photo = chat?.photo?.small ?? user?.profile_photo?.small;
    if (photo == null) {
      if (user?.type.userTypeDeleted != null) {
        return ChatColorAvatar(
          id: peerId,
          child: const Icon(FontAwesomeIcons.ghost, color: Colors.white),
        );
      }

      return ChatColorAvatar(
        id: peerId,
        child: Text(
          shortTitle,
          style: const TextStyle(color: Colors.white),
        ),
      );
    }

    Widget? avatar = avatarFromFile(photo.local.path);
    if (avatar != null) return avatar;
    var imageSourceb64 = chat?.photo?.minithumbnail?.data ??
        user?.profile_photo?.minithumbnail?.data;
    if (imageSourceb64 != null) {
      var imageSource = base64.decode(imageSourceb64);
      avatar = CircleAvatar(backgroundImage: MemoryImage(imageSource));
    }

    return Obx(
      () {
        var data = _downloadProfilePhoto.state[photo.id];
        return avatarFromFile(data) ??
            avatar ??
            ChatColorAvatar(
              id: peerId,
              child: Text(
                shortTitle,
                style: const TextStyle(color: Colors.white),
              ),
            );
      },
    );
  }

  Widget? avatarFromFile(String? path) {
    // debugPrint(path);
    if (path == null) return null;
    if (path.isEmpty) return null;
    var file = File(path);
    if (!file.existsSync()) return null;
    return CircleAvatar(backgroundImage: FileImage(file));
  }
}
