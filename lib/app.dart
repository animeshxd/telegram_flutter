import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tdffi/client.dart';

import 'telegram/auth/bloc/auth_bloc.dart';
import 'telegram/auth/login/view/routes.dart';
import 'telegram/auth/view/tdlib_init_failed_screen.dart';
import 'telegram/profile/services/download_profile_photo.dart';
import 'telegram/chat/cubit/chat_cubit.dart';
import 'telegram/chat/view/routes.dart';
import 'telegram/client_initializer/cubit/client_initializer_cubit.dart';
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
      GoRoute(
        path: '/error_tdlib',
        builder: (context, state) => TdlibInitFailedPage(
          error: state.extra as AuthStateTdlibInitilizedFailed,
        ),
      ),
      loginRoutes,
      chatRoute,
    ],
    debugLogDiagnostics: true,
  );
  @override
  void dispose() {
    super.dispose();
    _photoDownloader.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocAndRepositoryProvider(
      repositories: [
        RepositoryProvider.value(value: _tdlib),
        RepositoryProvider.value(value: _photoDownloader),
      ],
      blocs: [
        BlocProvider(create: (ctx) => ClientInitializerCubit(ctx.read())),
        BlocProvider(create: (context) => AuthBloc(context.read())),
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
