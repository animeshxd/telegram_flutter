import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tdffi/client.dart'
    show
        DefaultTdlibParameters,
        StreamExt,
        TdlibEventController,
        TdlibEventExt,
        TelegramError;
import 'package:tdffi/td.dart';

part 'auth_event.dart';
part 'auth_state.dart';

typedef AuthorizationStateEvent = AuthorizationState;

class AuthBloc extends Bloc<AuthorizationStateEvent, AuthState> {
  TdlibEventController client;

  AuthBloc(this.client) : super(AuthInitial()) {
    // debugPrint("Client: ${client.hashCode}");
    on<AuthInitiateEvent>((event, emit) {
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
      if (await client.currentAuthorizationState
          is AuthorizationStateWaitTdlibParameters) {
        var directory = await getApplicationCacheDirectory();
        int maxTries = 5;
        while (--maxTries >= 0) {
          try {
            await client.send(
              DefaultTdlibParameters(
                api_hash: '',
                api_id: 0,
                database_directory: directory.path,
                use_message_database: true,
              ),
            );
            emit(AuthStateTdlibInitilized());
            return;
          } on TelegramError catch (e) {
            if (e.message.contains("Can't lock file")) {
              debugPrint(e.message);
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
        } on TelegramError {
          emit(AuthStateBotTokenInvalid());
        }
      },
    );

    on<AuthPhoneNumberAquiredEvent>(
      (event, emit) async {
        try {
          await client.send(
              SetAuthenticationPhoneNumber(phone_number: event.phoneNumber));
        } on TelegramError {
          emit(AuthStatePhoneNumberInvalid());
        }
      },
    );
    on<AuthCodeAquiredEvent>((event, emit) async {
      try {
        await client.send(CheckAuthenticationCode(code: event.code));
      } on TelegramError {
        emit(AuthStateCodeInvalid());
      }
    });

    on<AuthorizationStateReady>((event, emit) async {
      var me = await client.send<User>(GetMe());
      var isBot = me.type is UserTypeBot;
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
  void onEvent(AuthorizationStateEvent event) {
    super.onEvent(event);
    debugPrint(event.runtimeType.toString());
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
    debugPrint("client closed");
    super.close();
  }
}



extension on TdlibEventController {
  Future<AuthorizationState> get currentAuthorizationState async =>
      await send<AuthorizationState>(GetAuthorizationState());
}
