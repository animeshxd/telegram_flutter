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
  final Rx<t.User> user;

  @override
  State<MyAccountsDrawerHeader> createState() => _MyAccountsDrawerHeaderState();
}

class _MyAccountsDrawerHeaderState extends State<MyAccountsDrawerHeader> {
  late final TdlibEventController tdlib;
  late final DownloadProfilePhoto downloadProfilePhoto;
  late final _me = widget.user;
  t.User get me => _me.value;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    tdlib = context.read();
    downloadProfilePhoto = context.read();

  }

  @override
  void dispose() {
    super.dispose();

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
