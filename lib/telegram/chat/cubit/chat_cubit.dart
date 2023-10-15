import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:get/state_manager.dart';
import 'package:logging/logging.dart';
import 'package:tdffi/client.dart';
import 'package:tdffi/td.dart' as t;

import '../models/chat.dart';
import '../../extensions/extension_tlobjects.dart';

part 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  late var logger = Logger(runtimeType.toString());
  final Tdlib tdlib;

  final _streamSubscriptions = <StreamSubscription>[];
  final _chats = <int, Chat>{}.obs;
  final _users = <int, t.User>{}.obs;
  final _ignoredChats = <int>{}.obs;

  ChatLoaded get _loadedState => ChatLoaded(
        chats: _chats,
        ignoredChats: _ignoredChats,
        users: _users,
      );
  final _idleDuration = const Duration(milliseconds: 1500);
  Timer? _idleTimer;
  bool _timerforLoadChatResult = false;

  void _emitForLoadChatResult() {
    emit(_loadedState);
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
      tdlib.updates
          .whereType<t.UpdateChatDraftMessage>()
          .listen(_onUpdateChatDraftMessage),
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
          .listen(_ignoredChats.add),
      tdlib.updates
          .whereType<t.UpdateSupergroup>()
          .map((event) => event.supergroup)
          .where((e) => !_whereChatMemberStatusBannedOrLeft(e.status))
          .map((event) => event.id)
          .listen(_ignoredChats.remove),
      tdlib.updates
          .whereType<t.UpdateBasicGroup>()
          .map((event) => event.basic_group)
          .where((e) => _whereChatMemberStatusBannedOrLeft(e.status))
          .map((event) => event.id)
          .listen(_ignoredChats.add),
      tdlib.updates
          .whereType<t.UpdateBasicGroup>()
          .map((event) => event.basic_group)
          .where((e) => !_whereChatMemberStatusBannedOrLeft(e.status))
          .map((event) => event.id)
          .listen(_ignoredChats.remove),
      tdlib.updates
          .whereType<t.UpdateUser>()
          .listen((user) => _users[user.user.id] = user.user),
      tdlib.updates.whereType<t.UpdateChatPhoto>().listen(_onUpdateChatPhoto),
    ]);
  }

  void _onUpdateChatPhoto(t.UpdateChatPhoto event) {
    _chats[event.chat_id]?.photo = event.photo;
    _chats.refresh();
  }

  void _onUpdateChatDraftMessage(t.UpdateChatDraftMessage event) {
    _chats.update(
      event.chat_id,
      (value) => value.update(
        draftMessage: event.draft_message,
        positions: event.positions,
        overrideDraftMessage: event.draft_message == null,
      ),
      ifAbsent: () => Chat.unknown(
        id: event.chat_id,
        draftMessage: event.draft_message,
        positions: event.positions,
      ),
    );
  }

  bool _whereChatMemberStatusBannedOrLeft(t.ChatMemberStatus status) {
    return status.chatMemberStatusLeft != null ||
        status.chatMemberStatusBanned != null;
  }

  void _onUpdateChatUnreadReactionCount(t.UpdateChatUnreadReactionCount event) {
    _chats.update(
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
    _chats.update(
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
    _chats.update(
      event.chat_id,
      (value) => value.update(unreadMessageCount: event.unread_count),
      ifAbsent: () => Chat.unknown(
        id: event.chat_id,
        unreadMessageCount: event.unread_count,
      ),
    );
  }

  void _onUpdateChatPosition(t.UpdateChatPosition event) {
    _chats.update(
      event.chat_id,
      (value) => value.update(positions: [event.position]),
      ifAbsent: () => Chat.unknown(
        id: event.chat_id,
        positions: [event.position],
      ),
    );
  }

  void _onUpdateChatTitle(t.UpdateChatTitle event) {
    _chats[event.chat_id]?.title = event.title;
    _chats.refresh();
  }

  void _onUpdateChatLastMessage(t.UpdateChatLastMessage event) {
    _chats.update(
      event.chat_id,
      (value) => value.update(
        positions: event.positions,
        lastMessage: event.last_message,
      ),
      ifAbsent: () => Chat.unknown(
        id: event.chat_id,
        positions: event.positions,
        lastMessage: event.last_message,
      ),
    );
  }

  void _onNewChat(t.Chat chat) {
    _chats.update(
      chat.id,
      (value) => value.updateFromTdChat(chat),
      ifAbsent: () => chat.mod,
    );
    if (_timerforLoadChatResult) {
      _idleTimer?.cancel();
      _idleTimer = Timer(_idleDuration, _emitForLoadChatResult);
    }
  }

  void loadChats(t.ChatList chatListType, {int limit = 10}) async {
    emit(ChatLoading());
    _timerforLoadChatResult = true;

    try {
      await tdlib.send(t.LoadChats(limit: limit, chat_list: chatListType));
      // emit(loadedState);
    } on TelegramError catch (e) {
      if (e.code == 404) {
        logger.shout('chat already loaded', e);
      } else {
        _timerforLoadChatResult = false;
        logger.shout(e, e);
        emit(ChatLoadedFailed());
      }
      // return emit(loadedState);
    } on Exception catch (e) {
      _timerforLoadChatResult = false;
      logger.shout(e, e);
      emit(ChatLoadedFailed());
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
