import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:nested/nested.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tdffi/client.dart'
    show TdlibEventController, defaultDynamicLibFile;

import 'telegram/auth/bloc/auth_bloc.dart';
import 'telegram/auth/login/bloc/login_bloc.dart';
import 'telegram/auth/login/view/routes.dart';
import 'telegram/auth/view/tdlib_init_failed_screen.dart';
import 'telegram/chat/controller/download_profile_photo.dart';
import 'telegram/chat/cubit/chat_cubit.dart';
import 'telegram/chat/view/routes.dart';
import 'telegram/client/bloc/telegram_client_bloc.dart';
import 'telegram/connection/cubit/connection_cubit.dart';

var dynamicLibPath =
    "/home/user/Project/dart/tdffi-dev/td/build/$defaultDynamicLibFile";

void main() {
  Logger.root.level = Level.ALL;
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
  }

  databaseFactory = databaseFactoryFfi;
  // Logger.root.onRecord.listen((event) => debugPrint(event.message));
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final _tdlib = TdlibEventController(dynamicLibPath: dynamicLibPath);
  late final _photoDownloader = DownloadProfilePhoto(_tdlib);

  final _routes = GoRouter(
    routes: [
      GoRoute(
        path: LoadingPage.path,
        builder: (context, state) => const LoadingPage(),
      ),
      chatRoute,
      GoRoute(
        path: '/error_tdlib',
        builder: (context, state) => TdlibInitFailedPage(
          error: state.extra as AuthStateTdlibInitilizedFailed,
        ),
      ),
      loginRoutes
    ],
    debugLogDiagnostics: true,
  );
  @override
  void dispose() {
    super.dispose();
    debugPrint("dispose called");
    _photoDownloader.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("build called");
    return MultiBlocAndRepositoryProvider(
      repositories: [
        RepositoryProvider.value(value: _tdlib),
        RepositoryProvider.value(value: _photoDownloader),
      ],
      blocs: [
        BlocProvider(create: (context) => TelegramClientBloc(context.read())),
        BlocProvider(create: (context) => AuthBloc(context.read())),
        BlocProvider(create: (context) => LoginBloc(context.read())),
        BlocProvider(create: (context) => ConnectionCubit(context.read())),
        BlocProvider(create: (context) => ChatCubit(context.read()))
      ],
      child: MaterialApp.router(
        routerConfig: _routes,
        theme: ThemeData(useMaterial3: true),
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
