import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:get/state_manager.dart';
import 'package:logging/logging.dart';
import 'package:tdffi/client.dart';
import 'package:tdffi/td.dart' as t;

import '../models/chat.dart';
import '../../../extensions/extension_tlobjects.dart';

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

  ChatLoaded get loadedState => ChatLoaded(
        totalChats: _totalChats,
        needLoaded: _needLoaded,
        chats: chats,
        ignoredChats: ignoredChats,
        lastMessages: lastMessages,
        users: users,
      );
  final idleDuration = const Duration(milliseconds: 1500);
  Timer? idleTimer;
  bool _timerforLoadChatResult = false;

  void _emitForLoadChatResult() {
    emit(loadedState);
    _timerforLoadChatResult = false;
  }

  void _debugUpdates(t.Update update) {
    // body unstaged
  }

  ChatCubit(this.tdlib) : super(ChatInitial()) {
    _streamSubscriptions.addAll([
      tdlib.updates.listen(_debugUpdates),
      tdlib.updates
          .whereType<t.UpdateNewChat>()
          .map((event) => event.chat)
          .listen(_onNewChat),
      tdlib.updates
          .whereType<t.UpdateChatLastMessage>()
          .listen(_onUpdateChatLastMessage),
      tdlib.updates.whereType<t.UpdateChatTitle>().listen(_onUpdateChatTitle),
      tdlib.updates
          .whereType<t.UpdateChatPosition>()
          .listen(_onUpdateChatPosition),
      tdlib.updates
          .whereType<t.UpdateChatReadInbox>()
          .listen(_onUpdateChatReadInbox),
      tdlib.updates
          .whereType<t.UpdateChatUnreadMentionCount>()
          .listen(_onUpdateChatUnreadMentionCount),
      tdlib.updates
          .whereType<t.UpdateChatUnreadReactionCount>()
          .listen(_onUpdateChatUnreadReactionCount),
      tdlib.updates
          .whereType<t.UpdateSupergroup>()
          .map((event) => event.supergroup)
          .where((e) => _whereChatMemberStatusBannedOrLeft(e.status))
          .map((event) => event.id)
          .listen(ignoredChats.add),
      tdlib.updates
          .whereType<t.UpdateSupergroup>()
          .map((event) => event.supergroup)
          .where((e) => !_whereChatMemberStatusBannedOrLeft(e.status))
          .map((event) => event.id)
          .listen(ignoredChats.remove),
      tdlib.updates
          .whereType<t.UpdateBasicGroup>()
          .map((event) => event.basic_group)
          .where((e) => _whereChatMemberStatusBannedOrLeft(e.status))
          .map((event) => event.id)
          .listen(ignoredChats.add),
      tdlib.updates
          .whereType<t.UpdateBasicGroup>()
          .map((event) => event.basic_group)
          .where((e) => !_whereChatMemberStatusBannedOrLeft(e.status))
          .map((event) => event.id)
          .listen(ignoredChats.remove),
      tdlib.updates
          .whereType<t.UpdateUser>()
          .listen((user) => users[user.user.id] = user.user),
    ]);
  }

  bool _whereChatMemberStatusBannedOrLeft(t.ChatMemberStatus status) {
    return status.chatMemberStatusLeft != null ||
        status.chatMemberStatusBanned != null;
  }

  void _onUpdateChatUnreadReactionCount(t.UpdateChatUnreadReactionCount event) {
    chats.update(
      event.chat_id,
      (value) => value.update(
        unreadReactionCount: event.unread_reaction_count,
      ),
      ifAbsent: () => Chat.unknown(
        id: event.chat_id,
        unreadReactionCount: event.unread_reaction_count,
      ),
    );
  }

  void _onUpdateChatUnreadMentionCount(t.UpdateChatUnreadMentionCount event) {
    chats.update(
      event.chat_id,
      (value) => value.update(
        unreadMentionCount: event.unread_mention_count,
      ),
      ifAbsent: () => Chat.unknown(
        id: event.chat_id,
        unreadMentionCount: event.unread_mention_count,
      ),
    );
  }

  void _onUpdateChatReadInbox(t.UpdateChatReadInbox event) {
    chats.update(
      event.chat_id,
      (value) => value.update(unreadMessageCount: event.unread_count),
      ifAbsent: () => Chat.unknown(
        id: event.chat_id,
        unreadMessageCount: event.unread_count,
      ),
    );
  }

  void _onUpdateChatPosition(t.UpdateChatPosition event) {
    chats.update(
      event.chat_id,
      (value) => value.update(positions: [event.position]),
      ifAbsent: () => Chat.unknown(
        id: event.chat_id,
        positions: [event.position],
      ),
    );
  }

  void _onUpdateChatTitle(t.UpdateChatTitle event) {
    chats[event.chat_id]?.title = event.title;
    chats.refresh();
  }

  void _onUpdateChatLastMessage(t.UpdateChatLastMessage event) {
    if (!chats.containsKey(event.chat_id)) {
      _updateNeedLoaded(event.positions);
    }
    lastMessages[event.chat_id] = event;
    if (event.last_message?.is_outgoing ?? false) return;
  }

  void _onNewChat(t.Chat chat) {
    _updateNeedLoaded(chat.positions);
    chats.update(
      chat.id,
      (value) => value.updateFromTdChat(chat),
      ifAbsent: () => chat.mod,
    );
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
    if (_timerforLoadChatResult) {
      idleTimer?.cancel();
      idleTimer = Timer(idleDuration, _emitForLoadChatResult);
    }
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
    _timerforLoadChatResult = true;

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
        // emit(loadedState);
      } on TelegramError catch (e) {
        if (e.code == 404) {
          logger.shout('chat already loaded', e);
        } else {
          rethrow;
        }
        // return emit(loadedState);
      }
    } on Exception catch (e) {
      _timerforLoadChatResult = false;
      logger.shout(e, e);
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
