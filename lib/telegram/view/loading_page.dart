import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tdffi/client.dart';

import '../auth/bloc/auth_bloc.dart';
import '../client_initializer/cubit/client_initializer_cubit.dart';

class LoadingPage extends StatefulWidget {
  static const path = '/';

  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  late TdlibEventController tdlib;
  late AuthBloc auth;

  @override
  void initState() {
    super.initState();
    tdlib = context.read();
    auth = context.read();
    context.read<ClientInitializerCubit>().initilize();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ClientInitializerCubit, ClientInitializerState>(
      listener: (context, state) {
        if (state == ClientInitializerState.initialized) {
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
