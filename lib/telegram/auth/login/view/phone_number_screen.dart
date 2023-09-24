import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/state_manager.dart';
import 'package:go_router/go_router.dart';

import '../../bloc/auth_bloc.dart';
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
  final _isSending = false.obs;
  final _phoneIssValidated = false.obs;
  final _isSubmitButtonFocused = false.obs;

  String? errorText;
  late AuthBloc authBloc;
  PhoneNumber? _phoneNumber;
  @override
  void initState() {
    super.initState();
    authBloc = context.read();
    if (widget.needAuthStateCheck) {
      authBloc.add(AuthCheckCurrentStateEvent());
    }
  }

  void _submitPhoneNumber() {
    if (_phoneNumber == null) return;
    _isSending.value = true;
    _isSubmitButtonFocused.value = false;
    context
        .read<AuthBloc>()
        .add(AuthPhoneNumberAquiredEvent(_phoneNumber!.completeNumber));
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
                _submitPhoneNumber();
                Navigator.of(context).maybePop();
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
          _isSending.value = false;
          _phoneIssValidated.value = false;
          _isSubmitButtonFocused.value = false;
          // context.showSnackBar(SnackBar(content: Text(state.error.message)));
          return;
        }
        if (state is AuthStatePhoneNumberOrBotTokenRequired) {
          return;
        }

        state.doRoute(context);
      },
      builder: (context, state) => Scaffold(
        appBar: AppBar(),
        floatingActionButton: Obx(
          () => FloatingActionButton(
            onPressed: !_isSending.value && _phoneIssValidated.value
                ? () => _onFormValidated(context)
                : null,
            child: _isSending.value
                ? const CircularProgressIndicator()
                : const Icon(Icons.navigate_next),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CountryAndPhoneNumberField(
                errorText: errorText,
                onValidated: (value) {
                  _phoneIssValidated.value = true;
                  _phoneNumber = value;
                  _isSubmitButtonFocused.value = true;
                },
                onChanged: (value) {
                  _phoneIssValidated.value = false;
                  _phoneNumber = value;
                  _isSubmitButtonFocused.value = false;
                },
              ),
              const SizedBox(height: 5),
              Obx(
                () => TextButton(
                  onPressed: _isSending.value
                      ? null
                      : () => context.replace(LoginAsBotPage.path),
                  child: const Text('Login with Bot Token'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
