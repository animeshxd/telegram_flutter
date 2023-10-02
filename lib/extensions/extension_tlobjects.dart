import 'package:tdffi/td.dart';
import '../telegram/chat/models/chat.dart' as m;

extension UserExt on User {
  String get fullName {
    return "$first_name $last_name".trim();
  }
}

extension ChatModExt on Chat {
  /// custom Chat object
  m.Chat get mod {
    return m.Chat(
      id: id,
      title: title,
      type: type,
      photo: photo,
      positions: positions,
      unreadMentionCount: unread_mention_count,
      unreadReactionCount: unread_reaction_count,
      unreadMessageCount: unread_count,
      lastMessage: last_message,
      draftMessage: draft_message,
    );
  }
}

extension MessageContentExt on MessageContent {
  bool get isChatActions => switch (runtimeType) {
        MessagePinMessage ||
        MessageContactRegistered ||
        MessageGameScore ||
        MessageChatJoinByLink ||
        MessageChatJoinByRequest ||
        MessageChatAddMembers ||
        MessageChatDeleteMember ||
        MessageGameScore ||
        MessageChatChangeTitle ||
        MessageChatSetMessageAutoDeleteTime ||
        MessageChatChangePhoto ||
        MessageChatDeletePhoto =>
          true,
        _ => false
      };
}
