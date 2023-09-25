import 'package:equatable/equatable.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:tdffi/td.dart' as t;

// ignore: must_be_immutable
class Chat extends Equatable {
  final int id;
  String title;
  List<t.ChatPosition> positions = [];
  t.ChatType type;
  t.ChatPhotoInfo? photo;
  final RxInt unreadMentionCount = 0.obs;
  final RxInt unreadReactionCount = 0.obs;
  final RxInt unreadMessageCount = 0.obs;
  Chat({
    required this.id,
    required this.title,
    required this.positions,
    required this.type,
    required this.photo,
    required int unreadMentionCount,
    required int unreadReactionCount,
    required int unreadMessageCount,
  }) {
    this.unreadMentionCount.value = unreadMentionCount;
    this.unreadReactionCount.value = unreadReactionCount;
    this.unreadMessageCount.value = unreadMessageCount;
  }

  Chat update({
    String? title,
    List<t.ChatPosition> positions = const [],
    t.ChatType? type,
    t.ChatPhotoInfo? photo,
    int? unreadMentionCount,
    int? unreadReactionCount,
    int? unreadMessageCount,
  }) {
    this.title = title ?? this.title;
    this.type = type ?? this.type;
    this.photo = photo ?? this.photo;
    this.unreadMentionCount.value =
        unreadMentionCount ?? this.unreadMentionCount.value;
    this.unreadMessageCount.value =
        unreadMessageCount ?? this.unreadMessageCount.value;
    this.unreadReactionCount.value =
        unreadReactionCount ?? this.unreadReactionCount.value;

    // update positions
    var map = Map.fromEntries(
      this.positions.map((e) => MapEntry(e.list.runtimeType, e)),
    );
    for (var e in positions) {
      map[e.list.runtimeType] = e;
    }
    this.positions = map.values.toList();

    return this;
  }

  Chat updateFromTdChat(t.Chat chat) {
    return update(
      title: chat.title,
      photo: chat.photo,
      positions: chat.positions,
      type: chat.type,
      unreadMentionCount: chat.unread_mention_count,
      unreadMessageCount: chat.unread_count,
      unreadReactionCount: chat.unread_reaction_count,
    );
  }

  Chat.unknown({
    required this.id,
    this.title = '',
    this.positions = const [],
    this.photo,
    int unreadMentionCount = 0,
    int unreadReactionCount = 0,
    int unreadMessageCount = 0,
  }) : type = ChatTypeUnknown() {
    this.unreadMentionCount.value = unreadMentionCount;
    this.unreadReactionCount.value = unreadReactionCount;
    this.unreadMessageCount.value = unreadMessageCount;
  }

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
