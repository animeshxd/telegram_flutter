import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:get/state_manager.dart';
import 'package:logging/logging.dart';
import 'package:tdffi/client.dart';
import 'package:tdffi/td.dart' as t;

part 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  late var logger = Logger(runtimeType.toString());
  final TdlibEventController tdlib;
  final _totalChats = <Type, int?>{
    t.ChatListMain: null,
    t.ChatListArchive: null,
    t.ChatListFolder: null,
  };
  final _needLoaded = <Type, int>{
    t.ChatListMain: 0,
    t.ChatListArchive: 0,
    t.ChatListFolder: 0
  };

  final _streamSubscriptions = <StreamSubscription>[];
  final chats = <int, Chat>{}.obs;
  final users = <int, t.User>{}.obs;
  var ignoredChats = <int>{}.obs;

  final lastMessages = <int, t.UpdateChatLastMessage>{}.obs;

  final unReadCount = <int, int>{}.obs;

  ChatLoaded get loadedState => ChatLoaded(
        totalChats: _totalChats,
        needLoaded: _needLoaded,
        chats: chats,
        ignoredChats: ignoredChats,
        lastMessages: lastMessages,
        unReadCount: unReadCount,
        users: users,
      );
  void _updateChat({
    required int id,
    required List<t.ChatPosition> positions,
    t.Chat? chat,
  }) {
    chats.update(
      id,
      (value) {
        var map = Map.fromEntries(
          value.positions.map((e) => MapEntry(e.list.runtimeType, e)),
        );
        for (var e in positions) {
          map[e.list.runtimeType] = e;
        }
        if (chat != null) value = chat.mod;
        value.positions = map.values.toList();
        return value;
      },
      ifAbsent: () =>
          chat?.mod ??
          Chat(
            title: '',
            id: id,
            positions: positions,
            type: ChatTypeUnknown(),
            photo: null,
          ),
    );
  }

  ChatCubit(this.tdlib) : super(ChatInitial()) {
    _streamSubscriptions.addAll([
      tdlib.updates
          .whereType<t.UpdateNewChat>()
          .map((event) => event.chat)
          .listen(
        (chat) {
          _updateNeedLoaded(chat.positions);
          _updateChat(id: chat.id, positions: chat.positions, chat: chat);
          unReadCount[chat.id] = chat.unread_count;
          lastMessages.update(
            chat.id,
            (value) {
              value.last_message = chat.last_message ?? value.last_message;
              return value;
            },
            ifAbsent: () => t.UpdateChatLastMessage(
              chat_id: chat.id,
              positions: chat.positions,
              last_message: chat.last_message,
            ),
          );
        },
      ),

      tdlib.updates
          .whereType<t.UpdateChatLastMessage>()
          // .where((event) => event.last_message != null)
          .listen((event) {
        if (!chats.containsKey(event.chat_id)) {
          _updateNeedLoaded(event.positions);
        }
        lastMessages[event.chat_id] = event;
        if (event.last_message?.is_outgoing ?? false) return;
      }),

      tdlib.updates.whereType<t.UpdateChatTitle>().listen((event) {
        chats[event.chat_id]?.title = event.title;
        chats.refresh();
      }),
      // tdlib.updates.listen(print)

      tdlib.updates.whereType<t.UpdateChatPosition>().listen(
            (event) => _updateChat(
              id: event.chat_id,
              positions: [event.position],
            ),
          ),

      tdlib.updates
          .whereType<t.UpdateChatReadInbox>()
          .listen((event) => unReadCount[event.chat_id] = event.unread_count),

      tdlib.updates
          .whereType<t.UpdateSupergroup>()
          .where(
              (event) => event.supergroup.status.chatMemberStatusLeft != null)
          .map((event) => event.supergroup.id)
          .listen(ignoredChats.add),

      tdlib.updates
          .whereType<t.UpdateBasicGroup>()
          .where(
              (event) => event.basic_group.status.chatMemberStatusLeft != null)
          .map((event) => event.basic_group.id)
          .listen(ignoredChats.add),

      tdlib.updates
          .whereType<t.UpdateUser>()
          .listen((user) => users[user.user.id] = user.user),
    ]);
  }

  void _updateNeedLoaded(List<t.ChatPosition> positions) {
    positions.map((element) => element.list.runtimeType).forEach(
          (element) => _needLoaded.update(
            element,
            (value) => value - 1,
            ifAbsent: () => 0,
          ),
        );
  }

  bool _isTotalChatNull(t.ChatList chatListType) =>
      _totalChats[chatListType.runtimeType] == null;

  void loadChats(t.ChatList chatListType) async {
    emit(ChatLoading());
    try {
      await _setTotalChatCountIfNull(chatListType);
      if (_isTotalChatNull(chatListType)) emit(ChatLoadedFailed());
      var needLoaded = _totalChats[chatListType.runtimeType]!;
      if (needLoaded == 0) {
        return emit(loadedState);
      }
      int limit = 10;
      if (needLoaded < limit) {
        limit = needLoaded;
      }

      try {
        await tdlib.send(t.LoadChats(limit: limit, chat_list: chatListType));
        emit(loadedState);
      } catch (_) {
        logger.shout('chat already loaded');
        return emit(loadedState);
      }
    } on Exception catch (e) {
      debugPrint(e.toString());
      emit(ChatLoadedFailed());
    }
  }

  Future<void> _setTotalChatCountIfNull(t.ChatList chatListType) async {
    if (_isTotalChatNull(chatListType)) {
      try {
        var chats = await tdlib.send<t.Chats>(t.GetChats(
          limit: 20,
          chat_list: chatListType,
        ));
        _totalChats[chatListType.runtimeType] = chats.total_count;
        _needLoaded[chatListType.runtimeType] = chats.total_count;
      } on TelegramError catch (e) {
        if (e.code == 420 && e.message.contains('FLOOD_WAIT_')) {
          var waittime = int.tryParse(e.message.replaceAll("FLOOD_WAIT_", ""));
          var chats = await Future.delayed(
            Duration(seconds: waittime ?? 0),
            () async => await tdlib.send<t.Chats>(
              t.GetChats(limit: 1, chat_list: chatListType),
            ),
          );
          _totalChats[chatListType.runtimeType] = chats.total_count;
          _needLoaded[chatListType.runtimeType] = chats.total_count;
        }
      }
    }
  }

  @override
  Future<void> close() async {
    await Future.wait(_streamSubscriptions.map((e) => e.cancel()));
    return super.close();
  }

  @override
  void onChange(Change<ChatState> change) {
    logger.fine(change);
    super.onChange(change);
  }
}

class ChatLoadedFailed extends ChatState {}

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

final class ChatTypeUnknown extends t.ChatType {
  @override
  Map<String, dynamic> toJson() => {};
}

extension on t.Chat {
  /// custom Chat object
  Chat get mod {
    return Chat(
      id: id,
      title: title,
      type: type,
      photo: photo,
      positions: positions,
    );
  }
}
