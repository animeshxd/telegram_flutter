import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:tdffi/client.dart';
import 'package:tdffi/td.dart';

class ConnectionCubit extends Cubit<ConnectionState?> {
  late final StreamSubscription _subscription;
  final TdlibEventController tdlib;
  ConnectionCubit(this.tdlib) : super(null) {
    _subscription = tdlib.updates
        .whereType<UpdateConnectionState>()
        .map((event) => event.state)
        .listen(emit);
  }
  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
