part of 'telegram_client_bloc.dart';

sealed class TelegramClientState extends Equatable {
  const TelegramClientState();

  @override
  List<Object> get props => [];
}

final class TelegramClientInitial extends TelegramClientState {
  const TelegramClientInitial();
}
