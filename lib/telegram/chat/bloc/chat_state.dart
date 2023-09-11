part of 'chat_bloc.dart';

sealed class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object> get props => [];
}

final class ChatInitial extends ChatState {}

final class ChatLoading extends ChatState {}

final class ChatLoaded extends ChatState {
  final int totalChats;
  final int needLoaded;
  final LinkedHashSet<t.Chat> chats;

  const ChatLoaded(
    this.totalChats,
    this.needLoaded,
    this.chats,
  );

  @override
  List<Object> get props => [
        totalChats,
        needLoaded,
        chats.length,
      ];
}