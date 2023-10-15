part of 'chat_cubit.dart';

sealed class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object> get props => [];
}

final class ChatInitial extends ChatState {}

final class ChatLoading extends ChatState {}

final class ChatLoaded extends ChatState {
  final RxMap<int, Chat> chats;
  final RxMap<int, t.User> users;
  final RxSet<int> ignoredChats;

  const ChatLoaded({
    required this.chats,
    required this.ignoredChats,
    required this.users,
  });

  Future<Chat> getChat(int id, Tdlib tdlib) async {
    var chat = chats[id];
    if (chat == null) {
      chat = (await tdlib.send<t.Chat>(t.GetChat(chat_id: id))).mod;
      chats[id];
    }
    return chat;
  }

  Future<t.User> getUser(int id, Tdlib tdlib) async {
    var user = users[id];
    if (user == null) {
      user = (await tdlib.send<t.User>(t.GetUser(user_id: id)));
      users[id] = user;
    }
    return user;
  }

  @override
  List<Object> get props => [
        chats.length,
        ignoredChats.length,
      ];
}
