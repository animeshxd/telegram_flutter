import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tdffi/client.dart';

import '../telegram/auth/bloc/auth_bloc.dart';
import '../telegram/client/bloc/telegram_client_bloc.dart';

class LoadingPage extends StatefulWidget {
  static const path = '/';

  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  late TdlibEventController tdlib;
  late TelegramClientBloc client;
  late AuthBloc auth;

  @override
  void initState() {
    super.initState();
    tdlib = context.read();
    client = context.read();
    auth = context.read();
    // debugPrint(tdlib.clientId.toString());
    client.add(const InitilizeClient());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TelegramClientBloc, TelegramClientState>(
      listener: (context, state) {
        if (state is ClientInitilizedState) {
          auth.add(AuthCheckCurrentStateEvent());
        }
      },
      child: Scaffold(
        appBar: AppBar(),
        body: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthStateTdlibInitilized) {
              auth.add(AuthCheckCurrentStateEvent());
              return;
            }
            state.doRoute(context);
          },
          builder: (context, state) =>
              const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}
