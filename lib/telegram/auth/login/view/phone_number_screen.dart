import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../bloc/auth_bloc.dart';
import '../bloc/login_bloc.dart';
import '../widgets/country_and_phone_number_field.dart';
import 'bot_token_screen.dart';

class LoginPhoneNumberPage extends StatefulWidget {
  static const subpath = "phoneNumber";
  static const path = "/login/phoneNumber";
  final bool needAuthStateCheck;
  const LoginPhoneNumberPage({super.key, this.needAuthStateCheck = true});

  @override
  State<LoginPhoneNumberPage> createState() => _LoginPhoneNumberPageState();
}

class _LoginPhoneNumberPageState extends State<LoginPhoneNumberPage> {
  bool _isSending = false;
  String? errorText;
  late AuthBloc authBloc;
  PhoneNumber? _phoneNumber;
  bool _phoneIssValidated = false;
  @override
  void initState() {
    super.initState();
    authBloc = context.read();
    if (widget.needAuthStateCheck) {
      authBloc.add(AuthCheckCurrentStateEvent());
    }
  }

  void _onFormValidated(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Is this the correct number?",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          content: Text(
            "+${_phoneNumber?.country.fullCountryCode} ${_phoneNumber?.number}",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Edit'),
            ),
            TextButton(
              onPressed: () {
                _isSending = true;
                context
                    .read<LoginBloc>()
                    .add(const SubmitButtonNotFocusedEvent());
                context.read<LoginBloc>().add(
                      FormSubmittedEvent(
                        state: SubmitButtonFocused(
                            completeNumber: _phoneNumber!.completeNumber),
                      ),
                    );
                Navigator.of(context).maybePop();
                // context.replace(OTPPage.path);
              },
              child: const Text('Login'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) => true,
      listener: (context, state) {
        if (state is AuthStatePhoneNumberInvalid) {
          errorText = state.error.message;
          _isSending = false;
          _phoneIssValidated = false;
          context.read<LoginBloc>().add(const SubmitButtonNotFocusedEvent());
          // context.showSnackBar(SnackBar(content: Text(state.error.message)));
          return;
        }
        if (state is AuthStatePhoneNumberOrBotTokenRequired) {
          return;
        }

        state.doRoute(context);
      },
      builder: (context, state) => BlocBuilder<LoginBloc, LoginState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(),
            floatingActionButton: FloatingActionButton(
              onPressed: !_isSending && _phoneIssValidated
                  ? () => _onFormValidated(context)
                  : null,
              child: _isSending
                  ? const CircularProgressIndicator()
                  : const Icon(Icons.navigate_next),
            ),
            body: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CountryAndPhoneNumberField(
                    errorText: errorText,
                    onValidated: (value) {
                      _phoneIssValidated = true;
                      _phoneNumber = value;
                      context.read<LoginBloc>().add(
                            SubmitButtonFocusedEvent(
                              completeNumber: value.completeNumber,
                            ),
                          );
                    },
                    onChanged: (value) {
                      _phoneNumber = value;
                      _phoneIssValidated = false;
                      context
                          .read<LoginBloc>()
                          .add(const SubmitButtonNotFocusedEvent());
                    },
                  ),
                  const SizedBox(height: 5),
                  TextButton(
                    onPressed: _isSending
                        ? null
                        : () => context.replace(LoginAsBotPage.path),
                    child: const Text('Login with Bot Token'),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
