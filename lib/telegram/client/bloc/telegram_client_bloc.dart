import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tdffi/client.dart';
import 'package:tdffi/td.dart';

part 'telegram_client_event.dart';
part 'telegram_client_state.dart';

class TelegramClientBloc
    extends Bloc<TelegramClientEvent, TelegramClientState> {
  TdlibEventController client;
  final _prefs = SharedPreferences.getInstance();

  TelegramClientBloc(this.client) : super(const TelegramClientInitial()) {
    on<ClientInitilizeEvent>((event, emit) async {
      await client.execute(SetLogVerbosityLevel(new_verbosity_level: 0));
      debugPrint("Initilizing Client");
      if (kDebugMode) {
        var oldId = (await _prefs).getInt('client');
        if (oldId != null) {
          client.clientId = oldId;
        }
        client.sendAsync(Close());
        debugPrint(client.clientId.toString());
        client.clientId = client.td_create_client_id();
        (await _prefs).setInt('client', client.clientId);
        debugPrint(client.clientId.toString());
      }
      await client.start();
      emit(ClientInitilizedState());
    });
  }

  @override
  Future<void> close() async {
    await client.destroy();
    debugPrint("client closed");

    super.close();
  }
}

final class ClientInitilizeEvent extends TelegramClientEvent {}

final class ClientInitilizedState extends TelegramClientState {}
