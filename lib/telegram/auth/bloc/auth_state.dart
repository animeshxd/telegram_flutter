part of 'auth_bloc.dart';

sealed class AuthState {
  const AuthState();
}

final class AuthInitial extends AuthState {}

final class AuthStateCriticalError extends AuthState {
  final TelegramError error;

  const AuthStateCriticalError(this.error);
}

final class AuthStateLoginRequired extends AuthState {}

final class AuthStateCurrentAccountReady extends AuthState {
  final bool isBot;
  final Rx<User> user;

  const AuthStateCurrentAccountReady(this.isBot, this.user);
}

final class AuthStatePhoneNumberOrBotTokenRequired extends AuthState {}

final class AuthStateCodeRequired extends AuthState {
  final AuthenticationCodeInfo codeInfo;

  const AuthStateCodeRequired({required this.codeInfo});
}

final class AuthStateBotTokenInvalid extends AuthState {}

final class AuthStatePhoneNumberInvalid extends AuthState {
  final TelegramError error;

  const AuthStatePhoneNumberInvalid({required this.error});
}

final class AuthStateCodeInvalid extends AuthState {
  final TelegramError error;

  const AuthStateCodeInvalid({required this.error});
}

final class AuthStateTdlibInitilized extends AuthState {}

final class AuthStateTdlibInitilizedFailed extends AuthState {
  final int tries;
  // ignore: non_constant_identifier_names, constant_identifier_names
  static const int MAX_TRIES = 5;

  const AuthStateTdlibInitilizedFailed(this.tries);
}


extension AuthStateExt on AuthState {
  /// Automatically do route based on state type
  void doRoute(BuildContext context) {
    if (this is AuthStateTdlibInitilizedFailed) {
      context.replace(TdlibInitFailedPage.path, extra: this);
    }
    if (this is AuthStateLoginRequired) {
      context.replace('/login');
    }
    if (this is AuthStateCodeRequired) {
      var codeInfo = (this as AuthStateCodeRequired).codeInfo;
      context.replace('/login/otp', extra: codeInfo);
    }
    if (this is AuthStateCodeInvalid) {
      context.replace('/login/otp#invalid');
    }
    if (this is AuthStatePhoneNumberOrBotTokenRequired) {
      context.replace('/login/phoneNumber');
    }
    if (this is AuthStatePhoneNumberInvalid) {
      context.replace('/login/phoneNumber#invalid');
    }
    if (this is AuthStateBotTokenInvalid) {
      context.replace("/login/botToken#invalid");
    }
    if (this is AuthStateCurrentAccountReady) {
      context.replace(ChatListScreen.path, extra: this);
    }
  }
}
