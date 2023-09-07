import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nested/nested.dart';
import 'package:tdffi/client.dart'
    show TdlibEventController, defaultDynamicLibFile;

import 'telegram/auth/bloc/auth_bloc.dart';
import 'telegram/auth/login/view/login_screen.dart';
import 'telegram/client/bloc/telegram_client_bloc.dart';

var dynamicLibPath =
    "/home/user/Project/dart/tdffi-dev/td/build/$defaultDynamicLibFile";

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiBlocAndRepositoryProvider(
      repositories: [
        RepositoryProvider(
          create: (context) =>
              TdlibEventController(dynamicLibPath: dynamicLibPath),
        ),
      ],
      blocs: [
        BlocProvider(create: (context) => TelegramClientBloc(context.read())),
        BlocProvider(create: (context) => AuthBloc(context.read()))
      ],
      child: MaterialApp(
        initialRoute: '/',
        routes: {
          "/": (context) => const LoadingScreen(),
          "/login": (context) => const LoginScreen(),
        },
      ),
    );
  }
}

class MultiBlocAndRepositoryProvider extends MultiRepositoryProvider {
  final Widget child;
  final List<SingleChildWidget> repositories;
  final List<SingleChildWidget> blocs;
  MultiBlocAndRepositoryProvider({
    super.key,
    required this.child,
    required this.repositories,
    required this.blocs,
  }) : super(
          providers: repositories,
          child: MultiBlocProvider(providers: blocs, child: child),
        );
}

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  late TdlibEventController client;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TelegramClientBloc, TelegramClientState>(
      builder: (context, state) {
        debugPrint(state.runtimeType.toString());
        if (state is ClientInitilizedState) {
          context.read<AuthBloc>().add(AuthInitiateEvent());

          return BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is! AuthStateTdlibInitilizedFailed) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (route) => false);
              } else if (state.tries == 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Failed to Initilize Client: Exit"),
                    action: SnackBarAction(
                      label: 'Exit',
                      onPressed: () {
                        //TODO: handle initilization failed

                        // context
                        //     .read<TdlibEventController>()
                        //     .destroy()
                        //     .then((value) => exit(0));
                      },
                    ),
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is AuthStateTdlibInitilizedFailed) {
                return Scaffold(
                  appBar: AppBar(
                    title: Text(
                      'Failed to Initilize Td: retrying: ${state.tries} / 5',
                    ),
                  ),
                  body: const LinearProgressIndicator(),
                );
              }
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: Colors.black),
                ),
              );
            },
          );
        }
        context.read<TelegramClientBloc>().add(ClientInitilizeEvent());
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
