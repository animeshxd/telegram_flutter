import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/login_bloc.dart';
import '../../bloc/auth_bloc.dart';
import 'phone_number_screen.dart';

class LoginAsBotPage extends StatefulWidget {
  const LoginAsBotPage({super.key});
  static const subpath = "botToken";
  static const path = "/login/botToken";

  @override
  State<LoginAsBotPage> createState() => _LoginAsBotPageState();
}

class _LoginAsBotPageState extends State<LoginAsBotPage> {
  final _botTokenController = TextEditingController();
  bool _isBotTokenValidated = false;
  bool _isSending = false;
  String? errorText;
  String botToken = '';

  late final LoginBloc _loginBloc;
  @override
  void initState() {
    super.initState();
    _loginBloc = context.read();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthStateBotTokenInvalid) {
          errorText = "invalid bot token";
          _isSending = false;
          _loginBloc.add(const SubmitButtonNotFocusedEvent());
          return;
        }
        state.doRoute(context);
      },
      builder: (context, state) => BlocBuilder<LoginBloc, LoginState>(
        builder: (context, state) {
          debugPrint(state.toString());
          return Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    controller: _botTokenController,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      label: const Text('Bot Token'),
                      hintText: '123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11',
                      errorText: errorText,
                    ),
                    autofocus: true,
                    onChanged: _onChanged,
                  ),
                  const SizedBox(height: 15),
                  TextButton(
                    onPressed: () => context.replace(LoginPhoneNumberPage.path),
                    child: const Text('Login with Phone Number'),
                  )
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed:
                  !_isSending && _isBotTokenValidated ? _submitBotToken : null,
              child: _isSending
                  ? const CircularProgressIndicator()
                  : const Icon(Icons.navigate_next),
            ),
          );
        },
      ),
    );
  }

  void _submitBotToken() {
    context.read<LoginBloc>().add(
        FormSubmittedEvent(state: SubmitButtonFocused(botToken: botToken)));
    _isSending = true;
  }

  void _onChanged(String value) {
    _isBotTokenValidated = false;
    _loginBloc.add(const SubmitButtonNotFocusedEvent());
    if (value.length > 42) {
      botToken = value;
      _isBotTokenValidated = true;
      _loginBloc.add(SubmitButtonFocusedEvent(botToken: value));
    }
  }
}
