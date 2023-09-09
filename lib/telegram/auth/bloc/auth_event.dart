part of 'auth_bloc.dart';

class CustomAuthEvent extends AuthorizationStateEvent {
  @override
  Map<String, dynamic> toJson() => {};
}

final class InitilizeAuthEvent extends CustomAuthEvent {}

final class AuthFailedEvent extends CustomAuthEvent {
  final TelegramError error;

  AuthFailedEvent(this.error);
}

final class AuthCheckCurrentStateEvent extends CustomAuthEvent {}

final class AuthPhoneNumberAquiredEvent extends CustomAuthEvent {
  final String phoneNumber;

  AuthPhoneNumberAquiredEvent(this.phoneNumber);
}

final class AuthPhoneBotTokenAquiredEvent extends CustomAuthEvent {
  final String token;

  AuthPhoneBotTokenAquiredEvent(this.token);
}

final class AuthCodeAquiredEvent extends CustomAuthEvent {
  final String code;

  AuthCodeAquiredEvent(this.code);
}
