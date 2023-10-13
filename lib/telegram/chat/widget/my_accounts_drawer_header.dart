import 'dart:convert';

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
  Widget build(BuildContext context) {
    return Obx(() {
      downloadProfilePhoto.downloadFile(me.profile_photo?.small);
      return userAccountDrawerHeaderFromListTile();
    });
  }

  Widget userAccountDrawerHeaderFromListTile() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListTile(
        leading: ChatAvatar(
          user: me,
        ),
        title: Text(me.fullName),
        subtitle: Text('+${me.phone_number}'),
      ),
    );
  }

  Container customUserAccountDrawerHeader() {
    return Container(
      height: MediaQuery.of(context).size.height * .34,
      decoration: getImageOrColorDecoration(me),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black.withOpacity(.6),
              Colors.black.withOpacity(.2),
              Colors.transparent
            ],
            begin: AlignmentDirectional.bottomEnd,
          ),
        ),
        padding: const EdgeInsets.only(left: 12, bottom: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              me.fullName,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w500, color: Colors.white),
            ),
            Text(
              '+${me.phone_number}',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w400, color: Colors.white),
            ),
          ],
        ),
      ),
      // switch to decoration
    );
  }

  UserAccountsDrawerHeader userAccountsDrawerHeader() {
    return UserAccountsDrawerHeader(
      accountName: Text(me.fullName),
      accountEmail: Text('+${me.phone_number}'),
      decoration: getImageOrColorDecoration(me),
      // currentAccountPicture: ChatAvatar(user: me),
    );
  }

  Decoration? getImageOrColorDecoration(t.User user) {
    var photo = user.profile_photo?.big;
    String? path = downloadProfilePhoto.state[photo?.id ?? 0];
    if (path != null) {
      var image = getImageWFromFile(path);
      if (image != null) {
        return BoxDecoration(
          image: DecorationImage(
            image: image,
            fit: BoxFit.cover,
          ),
        );
      }
    }
    if (photo != null) {
      var image = getImageWFromFile(photo.local.path);
      if (image != null) {
        return BoxDecoration(
          image: DecorationImage(
            image: image,
            fit: BoxFit.cover,
          ),
        );
      }
    }
    var imageSourceb64 = user.profile_photo?.minithumbnail?.data;
    if (imageSourceb64 != null) {
      var imageSource = base64.decode(imageSourceb64);
      return BoxDecoration(
        image:
            DecorationImage(image: MemoryImage(imageSource), fit: BoxFit.cover),
      );
    }

    return BoxDecoration(color: ChatColorAvatar.getColor(user.id));
  }
}
