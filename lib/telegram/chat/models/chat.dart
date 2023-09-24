import 'package:equatable/equatable.dart';
import 'package:tdffi/td.dart' as t;

// ignore: must_be_immutable
class Chat extends Equatable {
  final int id;
  String title;
  List<t.ChatPosition> positions = [];
  t.ChatType type;
  t.ChatPhotoInfo? photo;
  Chat({
    required this.id,
    required this.title,
    required this.positions,
    required this.type,
    required this.photo,
  });

  @override
  List<Object?> get props => [id, title, positions.length];
}

extension ChatExt on Chat {
  bool get isChannel => (type.chatTypeSupergroup?.is_channel ?? false);
  bool get isGroup =>
      !isChannel && type.chatTypePrivate == null && type.chatTypeSecret == null;
  bool get isPrivate => (type.chatTypePrivate != null);
}

final class ChatTypeUnknown extends t.ChatType {
  @override
  Map<String, dynamic> toJson() => {};
}
