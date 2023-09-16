part of 'chat_cubit.dart';

sealed class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object> get props => [];
}

final class ChatInitial extends ChatState {}

final class ChatLoading extends ChatState {}

final class ChatLoaded extends ChatState {
  final Map<Type, int?> totalChats;
  final Map<Type, int> needLoaded;
  final RxMap<int, Chat> chats;
  final RxMap<int, t.User> users;
  final RxMap<int, t.UpdateChatLastMessage> lastMessages;
  final RxMap<int, int> unReadCount;
  final RxSet<int> ignoredChats;

  const ChatLoaded({
    required this.totalChats,
    required this.needLoaded,
    required this.chats,
    required this.ignoredChats,
    required this.users,
    required this.lastMessages,
    required this.unReadCount,
  });

  @override
  List<Object> get props => [
        totalChats,
        needLoaded,
        chats.length,
        ignoredChats.length,
        lastMessages.length,
        unReadCount.length,
      ];
}
