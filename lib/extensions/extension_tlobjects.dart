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
    );
  }
}
