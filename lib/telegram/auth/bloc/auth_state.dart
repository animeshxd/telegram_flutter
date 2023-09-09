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
  final User user;

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

// class AuthCheckCurrentStateRequired extends AuthState {}
