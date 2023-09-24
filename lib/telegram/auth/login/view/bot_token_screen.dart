import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/state_manager.dart';
import 'package:go_router/go_router.dart';
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
  final _isBotTokenValidated = false.obs;
  final _isSending = false.obs;
  final _isSubmitButtonFocused = false.obs;
  String? errorText;
  String botToken = '';

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthStateBotTokenInvalid) {
          errorText = "invalid bot token";
          _isSending.value = false;
          _isSubmitButtonFocused.value = false;
          return;
        }
        state.doRoute(context);
      },
      builder: (context, state) => Scaffold(
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
        floatingActionButton: Obx(
          () => FloatingActionButton(
            onPressed: !_isSending.value && _isBotTokenValidated.value
                ? _submitBotToken
                : null,
            child: _isSending.value
                ? const CircularProgressIndicator()
                : const Icon(Icons.navigate_next),
          ),
        ),
      ),
    );
  }

  void _submitBotToken() {
    context.read<AuthBloc>().add(AuthPhoneBotTokenAquiredEvent(botToken));
    _isSending.value = true;
  }

  void _onChanged(String value) {
    _isBotTokenValidated.value = false;
    _isSubmitButtonFocused.value = false;
    if (value.length > 42) {
      botToken = value;
      _isBotTokenValidated.value = true;
      _isSubmitButtonFocused.value = true;
    }
  }
}
