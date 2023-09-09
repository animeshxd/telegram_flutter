import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tdffi/client.dart';
import 'package:tdffi/td.dart';

part 'telegram_client_event.dart';
part 'telegram_client_state.dart';

var logger = Logger('TelegramClientBloc');

class TelegramClientBloc
    extends Bloc<TelegramClientEvent, TelegramClientState> {
  TdlibEventController client;
  final _prefs = SharedPreferences.getInstance();
  bool initilized = false;

  TelegramClientBloc(this.client) : super(const TelegramClientInitial()) {
    on<InitilizeClient>((event, emit) async {
      if (!initilized || event.force) {
        await client.execute(SetLogVerbosityLevel(new_verbosity_level: 0));
        debugPrint("Initilizing Client");
        if (kDebugMode) {
          var oldId = (await _prefs).getInt('client');
          if (oldId != null) {
            client.clientId = oldId;
          }
          client.sendAsync(Close());
          // debugPrint(client.clientId.toString());
          client.clientId = client.td_create_client_id();
          (await _prefs).setInt('client', client.clientId);
          // debugPrint(client.clientId.toString());
        }
        await client.start();
        initilized = true;
        emit(ClientInitilizedState());
      }
    });
  }

  @override
  Future<void> close() async {
    await client.destroy();
    logger.fine("client closed");

    super.close();
  }

  @override
  void onEvent(TelegramClientEvent event) {
    super.onEvent(event);
    logger.fine(event);
  }

  @override
  void onChange(Change<TelegramClientState> change) {
    super.onChange(change);
    debugPrint(change.currentState.toString());
  }
}

final class InitilizeClient extends TelegramClientEvent {
  final bool force;

  const InitilizeClient({this.force = false});
  @override
  List<Object> get props => [force];
}

final class ClientInitilizedState extends TelegramClientState {}
