part of 'telegram_client_bloc.dart';

sealed class TelegramClientState {
  const TelegramClientState();
}

final class TelegramClientInitial extends TelegramClientState {
  const TelegramClientInitial();
}
