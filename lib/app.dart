import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tdffi/client.dart';

import 'telegram/auth/bloc/auth_bloc.dart';
import 'telegram/auth/login/bloc/login_bloc.dart';
import 'telegram/auth/login/view/routes.dart';
import 'telegram/auth/view/tdlib_init_failed_screen.dart';
import 'telegram/chat/controller/download_profile_photo.dart';
import 'telegram/chat/cubit/chat_cubit.dart';
import 'telegram/chat/view/routes.dart';
import 'telegram/client/bloc/telegram_client_bloc.dart';
import 'telegram/connection/cubit/connection_cubit.dart';
import 'view/loading_page.dart';
import 'widget/multi_bloc_and_repository_provider.dart';

var dynamicLibPath =
    "/home/user/Project/dart/tdffi-dev/td/build/$defaultDynamicLibFile";

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
