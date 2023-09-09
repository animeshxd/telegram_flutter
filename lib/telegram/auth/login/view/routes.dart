import 'package:go_router/go_router.dart';
import 'package:tdffi/td.dart';
import 'package:telegram_flutter/telegram/auth/login/view/bot_token_screen.dart';
import 'otp_screen.dart';
import 'phone_number_screen.dart';

GoRoute loginRoutes = GoRoute(
  redirect: (context, state) {
    if (state.fullPath == '/login') {
      return LoginPhoneNumberPage.path;
    }
    return null;
  },
  path: '/login',
  routes: [
    GoRoute(
      path: LoginPhoneNumberPage.subpath,
      builder: (context, state) =>
          LoginPhoneNumberPage(needAuthStateCheck: !state.uri.hasFragment),
    ),
    GoRoute(
      path: LoginAsBotPage.subpath,
      builder: (context, state) => const LoginAsBotPage(),
    ),
    GoRoute(
      path: OTPPage.subpath,
      builder: (context, state) => OTPPage(
        codeInfo: state.extra as AuthenticationCodeInfo,
      ),
    ),
  ],
);
