import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tdffi/client.dart';
import 'package:tdffi/td.dart';

import '../../chat/view/chat_list_screen.dart';
import '../view/tdlib_init_failed_screen.dart';

part 'auth_event.dart';
part 'auth_state.dart';

typedef AuthorizationStateEvent = AuthorizationState;

var logger = Logger('AuthBloc');

class AuthBloc extends Bloc<AuthorizationStateEvent, AuthState> {
  TdlibEventController client;
  StreamSubscription? _subscriptionForCurrentUser;

  AuthBloc(this.client) : super(AuthInitial()) {
    on<InitilizeAuthEvent>((event, emit) {
      client.updates
          .whereType<UpdateAuthorizationState>()
          .map((event) => event.authorization_state)
          .listen(add);
      add(AuthCheckCurrentStateEvent());
    });

    on<AuthFailedEvent>(
      (event, emit) => emit(AuthStateCriticalError(event.error)),
    );

    on<AuthCheckCurrentStateEvent>((event, emit) async {
      var state =
          await client.send<AuthorizationState>(GetAuthorizationState());
      add(state);
    });

    on<AuthorizationStateWaitTdlibParameters>((event, emit) async {
      var currentAuthState = await client.currentAuthorizationState;
      if (currentAuthState is AuthorizationStateWaitTdlibParameters) {
        var directory = await getApplicationCacheDirectory();
        int maxTries = AuthStateTdlibInitilizedFailed.MAX_TRIES;
        while (--maxTries >= 0) {
          try {
            await client.send(
              DefaultTdlibParameters(
                api_hash: '358df460e06a3e54e158276c1293790c',
                api_id: 3334083,
                database_directory: directory.path,
                use_message_database: true,
                use_file_database: true,
                use_chat_info_database: true,
                use_test_dc: false,
              ),
            );
            emit(AuthStateTdlibInitilized());
            return;
          } on TelegramError catch (e) {
            if (e.message.contains("Can't lock file")) {
              logger.shout(e);
              emit(AuthStateTdlibInitilizedFailed(maxTries));
              await Future.delayed(const Duration(milliseconds: 1));
              continue;
            }
            if (e.message == 'Unexpected setTdlibParameters') {
              return;
            } else {
              rethrow;
            }
          }
        }
        if (maxTries == 0) {
          emit(const AuthStateTdlibInitilizedFailed(0));
        }
      }
    });
    on<AuthorizationStateWaitPhoneNumber>(
        (event, emit) => emit(AuthStatePhoneNumberOrBotTokenRequired()));

    on<AuthorizationStateWaitCode>((event, emit) {
      emit(AuthStateCodeRequired(codeInfo: event.code_info));
    });

    on<AuthPhoneBotTokenAquiredEvent>(
      (event, emit) async {
        try {
          await client.send(CheckAuthenticationBotToken(token: event.token));
          add(AuthCheckCurrentStateEvent());
        } on TelegramError {
          emit(AuthStateBotTokenInvalid());
        }
      },
    );

    on<AuthPhoneNumberAquiredEvent>(
      (event, emit) async {
        try {
          var result = await client.send(
            SetAuthenticationPhoneNumber(phone_number: event.phoneNumber),
          );
          logger.fine(result);
          add(AuthCheckCurrentStateEvent());
        } on TelegramError catch (e) {
          logger.shout(e);
          emit(AuthStatePhoneNumberInvalid(error: e));
        }
      },
    );
    on<AuthCodeAquiredEvent>((event, emit) async {
      try {
        await client.send(CheckAuthenticationCode(code: event.code));
        add(AuthCheckCurrentStateEvent());
      } on TelegramError catch (e) {
        emit(AuthStateCodeInvalid(error: e));
      }
    });
    on<AuthorizationStateReady>((event, emit) async {
      await _subscriptionForCurrentUser?.cancel();

      var me = (await client.send<User>(GetMe())).obs;

      _subscriptionForCurrentUser = client.updates
          .whereType<UpdateUser>()
          .where((event) => event.user.id == me.value.id)
          .listen((event) => me.value = event.user);

      var isBot = me.value.type is UserTypeBot;
      emit(AuthStateCurrentAccountReady(isBot, me));
    });

    on<AuthorizationStateClosing>((event, emit) async {
      emit(AuthStateLoginRequired());
    });
    on<AuthorizationStateClosed>((event, emit) async {
      emit(AuthStateLoginRequired());
    });
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    if (error is TelegramError) {
      add(AuthFailedEvent(error));
      return;
    }
    super.onError(error, stackTrace);
  }

  @override
  Future<void> close() async {
    await client.destroy();
    _subscriptionForCurrentUser?.cancel();
    logger.fine("client closed");
    super.close();
  }
}

extension on TdlibEventController {
  Future<AuthorizationState> get currentAuthorizationState async =>
      await send<AuthorizationState>(GetAuthorizationState());
}
