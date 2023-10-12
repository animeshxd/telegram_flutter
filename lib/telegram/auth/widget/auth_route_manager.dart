import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:telegram_flutter/telegram/auth/bloc/auth_bloc.dart';

class AuthRouteManager extends StatelessWidget {
  const AuthRouteManager({super.key, required this.child, this.listenWhen});
  final Widget child;
  final BlocListenerCondition<AuthState>? listenWhen;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: listenWhen ??
          (previous, current) => current is! AuthStateCurrentAccountReady,
      listener: (context, state) => state.doRoute(context),
      child: child,
    );
  }
}
