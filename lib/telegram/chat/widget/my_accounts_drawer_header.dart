import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:tdffi/client.dart';
import 'package:tdffi/td.dart' as t;
import '../../../extensions/extensions.dart';

import '../../profile/services/download_profile_photo.dart';
import 'chat_avatar.dart';

class MyAccountsDrawerHeader extends StatefulWidget {
  const MyAccountsDrawerHeader({super.key, required this.user});
  final t.User user;

  @override
  State<MyAccountsDrawerHeader> createState() => _MyAccountsDrawerHeaderState();
}


class _MyAccountsDrawerHeaderState extends State<MyAccountsDrawerHeader> {
  StreamSubscription? subscription;
  late final TdlibEventController tdlib;
  late final DownloadProfilePhoto downloadProfilePhoto;
  late final _me = widget.user.obs;
  t.User get me => _me.value;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    tdlib = context.read();
    downloadProfilePhoto = context.read();

    subscription = tdlib.updates
        .whereType<t.UpdateUser>()
        .where((event) => event.user.id == _me.value.id)
        .listen((event) => _me.value = event.user);
  }

  @override
  void dispose() {
    super.dispose();
    subscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      downloadProfilePhoto.downloadFile(me.profile_photo?.small);
      return UserAccountsDrawerHeader(
        accountName: Text(me.fullName),
        accountEmail: Text('+${me.phone_number}'),
        currentAccountPicture: ChatAvatar(user: me),
        // switch to decoration
      );
    });
  }
}
