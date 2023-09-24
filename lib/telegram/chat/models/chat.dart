import 'package:equatable/equatable.dart';
import 'package:tdffi/td.dart' as t;

// ignore: must_be_immutable
class Chat extends Equatable {
  final int id;
  String title;
  List<t.ChatPosition> positions = [];
  t.ChatType type;
  t.ChatPhotoInfo? photo;
  int unreadMentionCount;
  int unreadReactionCount;
  Chat({
    required this.id,
    required this.title,
    required this.positions,
    required this.type,
    required this.photo,
    required this.unreadMentionCount,
    required this.unreadReactionCount,
  });

  Chat.unknown({
    required this.id,
    this.title = '',
    this.positions = const [],
    this.photo,
    this.unreadMentionCount = 0,
    this.unreadReactionCount = 0,
  }) : type = ChatTypeUnknown();

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
