import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tdffi/client.dart';
import 'package:tdffi/td.dart';

class ClientInitializerCubit extends Cubit<ClientInitializerState> {
  ClientInitializerCubit(this.tdlib) : super(ClientInitializerState.required);

  final TdlibEventController tdlib;
  final _prefs = SharedPreferences.getInstance();
  Future<void> initilize([bool force = false]) async {
    if (state == ClientInitializerState.required || force) {
      await tdlib.execute(SetLogVerbosityLevel(new_verbosity_level: 0));
      if (kDebugMode) {
        var oldId = (await _prefs).getInt('client');
        if (oldId != null) {
          tdlib.clientId = oldId;
        }
        tdlib.sendAsync(Close());
        tdlib.clientId = tdlib.td_create_client_id();
        (await _prefs).setInt('client', tdlib.clientId);
      }
      await tdlib.start();
    }
    emit(ClientInitializerState.initialized);
  }
}

enum ClientInitializerState { required, initializing, initialized }
