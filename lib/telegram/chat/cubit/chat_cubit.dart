import 'dart:async';
import 'dart:collection';

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
  StreamSubscription<t.Chat>? _chatSubscription;
  StreamSubscription? _chatHistorySubscription;
  StreamSubscription? _updateNewMessageSubscription;
  final chats = LinkedHashSet<t.Chat>(
    equals: (chat0, chat1) => chat0.id == chat1.id,
    hashCode: (c) => c.id.hashCode,
  );

  final lastMessages = <int, t.Message>{}.obs;

  ChatCubit(this.tdlib) : super(ChatInitial()) {
    _chatSubscription = tdlib.updates
        .whereType<t.UpdateNewChat>()
        .map((event) => event.chat)
        .listen(chats.add);

    _chatHistorySubscription = tdlib.updates
        .whereType<t.UpdateChatLastMessage>()
        .where((event) => event.last_message != null)
        .listen((event) => lastMessages[event.chat_id] = event.last_message!);

    _updateNewMessageSubscription = tdlib.updates
        .whereType<t.UpdateNewMessage>()
        .listen((event) => lastMessages[event.message.chat_id] = event.message);
  }
      void loadChats() async {
      emit(ChatLoading());
      try {
        await _setTotalChatCountIfNull();
        if (totalChats == null) emit(ChatLoadedFailed());
        int limit = 10;
        if (needLoaded < limit) {
          limit = needLoaded;
        }
        needLoaded = needLoaded - 10;

        try {
          await tdlib.send(t.LoadChats(limit: limit));
        } catch (_) {
          logger.shout('chat already loaded');
          return emit(ChatLoaded(totalChats!, needLoaded, chats, lastMessages));
        }

        var set = await tdlib.updates
            .whereType<t.UpdateNewChat>()
            .map((event) => event.chat)
            .take(limit)
            .timeout(const Duration(seconds: 5), onTimeout: (sink) {})
            .toSet();
        chats.addAll(set);

        emit(ChatLoaded(totalChats!, needLoaded, chats, lastMessages));
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
  Future<void> close() {
    _chatSubscription?.cancel();
    _chatHistorySubscription?.cancel();
    _updateNewMessageSubscription?.cancel();
    return super.close();
  }

  @override
  void onChange(Change<ChatState> change) {
    logger.fine(change);
    super.onChange(change);
  }

}

class ChatLoadedFailed extends ChatState {}
