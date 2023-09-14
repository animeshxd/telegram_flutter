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
  int? totalChats;
  int needLoaded = 0;
  final _streamSubscriptions = <StreamSubscription>[];
  final chats = <int, Chat>{}.obs;

  final lastMessages = <int, t.UpdateChatLastMessage>{}.obs;

  final unReadCount = <int, int>{}.obs;

  ChatCubit(this.tdlib) : super(ChatInitial()) {
    _streamSubscriptions.addAll([
      tdlib.updates
          .whereType<t.UpdateNewChat>()
          .map((event) => event.chat)
          .listen(
        (chat) {
          needLoaded--;
          chats[chat.id] = chat.mod;
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
          .where((event) => event.last_message != null)
          .listen((event) {
        lastMessages[event.chat_id] = event;
        if (event.last_message?.is_outgoing ?? false) return;
        unReadCount.update(
          event.chat_id,
          (value) => value + 1,
          ifAbsent: () => 0,
        );
      }),

      tdlib.updates
          .whereType<t.UpdateChatTitle>()
          .listen((event) => chats[event.chat_id]?.title = event.title),
      // tdlib.updates.listen(print)

      tdlib.updates.whereType<t.UpdateChatPosition>().listen(
            (event) => chats.update(
              event.chat_id,
              (value) {
                value.positions.removeWhere(
                  (element) =>
                      element.runtimeType == event.position.runtimeType,
                );
                value.positions.add(event.position);
                return value;
              },
              ifAbsent: () => Chat(
                title: '',
                id: event.chat_id,
                positions: [event.position],
                type: ChatTypeUnknown(),
                photo: null,
              ),
            ),
          ),

      tdlib.updates
          .whereType<t.UpdateChatReadInbox>()
          .listen((event) => unReadCount[event.chat_id] = event.unread_count),

    ]);
  }
  void loadChats() async {
    emit(ChatLoading());
    try {
      await _setTotalChatCountIfNull();
      if (totalChats == null) emit(ChatLoadedFailed());
      if (needLoaded == 0) {
        return emit(ChatLoaded(
          totalChats!,
          needLoaded,
          chats,
          lastMessages,
          unReadCount,
        ));
      }
      int limit = 10;
      if (needLoaded < limit) {
        limit = needLoaded;
      }

      try {
        await tdlib.send(t.LoadChats(limit: limit));
      } catch (_) {
        logger.shout('chat already loaded');
        return emit(ChatLoaded(
          totalChats!,
          needLoaded,
          chats,
          lastMessages,
          unReadCount,
        ));
      }

      var set = await tdlib.updates
          .whereType<t.UpdateNewChat>()
          .map((event) => event.chat)
          .map((chat) => MapEntry(chat.id, chat.mod))
          .take(limit)
          .timeout(const Duration(seconds: 5), onTimeout: (sink) {})
          .toList();
      chats.addEntries(set);

      emit(ChatLoaded(
        totalChats!,
        needLoaded,
        chats,
        lastMessages,
        unReadCount,
      ));
    } on Exception catch (e) {
      debugPrint(e.toString());
      emit(ChatLoadedFailed());
    }
  }

  Future<void> _setTotalChatCountIfNull() async {
    if (totalChats == null) {
      try {
        var chats = await tdlib.send<t.Chats>(t.GetChats(limit: 20));
        totalChats = chats.total_count;
        needLoaded = chats.total_count;
      } on TelegramError catch (e) {
        if (e.code == 420 && e.message.contains('FLOOD_WAIT_')) {
          var waittime = int.tryParse(e.message.replaceAll("FLOOD_WAIT_", ""));
          var chats = await Future.delayed(
            Duration(seconds: waittime ?? 0),
            () async => await tdlib.send<t.Chats>(t.GetChats(limit: 1)),
          );
          totalChats = chats.total_count;
          needLoaded = chats.total_count;
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
