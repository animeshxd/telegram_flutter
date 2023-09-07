part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
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

  @override
  List<Object> get props => [isBot, user];
}

final class AuthStatePhoneNumberOrBotTokenRequired extends AuthState {}

final class AuthStateCodeRequired extends AuthState {
  final AuthenticationCodeInfo codeInfo;

  const AuthStateCodeRequired({required this.codeInfo});
}

final class AuthStateBotTokenInvalid extends AuthState {}

final class AuthStatePhoneNumberInvalid extends AuthState {}

final class AuthStateCodeInvalid extends AuthState {}

final class AuthStateTdlibInitilized extends AuthState {}

final class AuthStateTdlibInitilizedFailed extends AuthState {
  final int tries;
  @override
  List<Object> get props => [tries];

  const AuthStateTdlibInitilizedFailed(this.tries);
}
