import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:tdffi/td.dart' as t;

import '../../bloc/auth_bloc.dart';
import '../bloc/login_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.read<AuthBloc>().add(AuthCheckCurrentStateEvent());
    return BlocProvider(
      create: (context) => LoginBloc(),
      child: const Scaffold(body: LoginForm()),
    );
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          current is t.AuthorizationStateReady ||
          current is AuthStateCurrentAccountReady,
      listener: (context, state) {
        if(context.mounted) {
          // Navigator.of(context).pushNamedAndRemoveUntil(newRouteName, (route) => false);
        }
      },
      builder: (context, authState) {
        // debugPrint(authState.toString());
        if (authState is AuthStatePhoneNumberOrBotTokenRequired ||
            authState is AuthStateCodeRequired) {
          var s = MediaQuery.of(context).size;
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: s.width < 800 ? s.width * .7 : s.width * .3,
                child: Column(
                  children: [
                    if (authState is AuthStatePhoneNumberOrBotTokenRequired)
                      IntlPhoneField(
                        initialCountryCode: 'IN',
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(),
                          ),
                        ),
                        onChanged: (value) {
                          var loginBloc = context.read<LoginBloc>();
                          try {
                            debugPrint(
                                "${value.isValidNumber()}: ${value.completeNumber}");
                            loginBloc.add(SubmitButtonFocusedEvent(
                              completeNumber: value.completeNumber,
                            ));
                          } catch (_) {
                            loginBloc.add(SubmitButtonNotFocusedEvent());
                          }
                        },
                      ),
                    if (authState is AuthStateCodeRequired)
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'OTP',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(),
                          ),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            context
                                .read<LoginBloc>()
                                .add(SubmitButtonFocusedEvent(code: value));
                          }
                        },
                      ),
                    BlocBuilder<LoginBloc, LoginState>(
                      builder: (context, state) {
                        var message = 'Continue';
                        if (state is SubmitButtonFocused) {
                          message = state.code.isEmpty ? message : 'Submit OTP';
                        }
                        return ElevatedButton(
                          onPressed: state is SubmitButtonFocused
                              ? () {
                                  var event = state.completeNumber.isNotEmpty
                                      ? AuthPhoneNumberAquiredEvent(
                                          state.completeNumber)
                                      : state.botToken.isNotEmpty
                                          ? AuthPhoneBotTokenAquiredEvent(
                                              state.botToken)
                                          : AuthCodeAquiredEvent(state.code);
                                  context.read<AuthBloc>().add(event);
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.fromLTRB(40, 20, 40, 20),
                          ),
                          child: Text(message),
                        );
                      },
                    )
                  ],
                ),
              ),
            ),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
