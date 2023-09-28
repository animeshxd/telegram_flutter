import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:tdffi/td.dart' as t;
import 'phone_number_screen.dart';

import '../../bloc/auth_bloc.dart';
import '../widgets/otp_field.dart';
import '../widgets/phone_number_field.dart';

var logger = Logger('OTPPage');

class OTPPage extends StatefulWidget {
  static const subpath = "otp";
  static const path = "/login/otp";
  final t.AuthenticationCodeInfo codeInfo;
  const OTPPage({super.key, required this.codeInfo});

  @override
  State<OTPPage> createState() => _OTPPageState();
}

class _OTPPageState extends State<OTPPage> {
  int? otpLenght;
  List<String> messages = [];
  t.AuthenticationCodeType get codeType => widget.codeInfo.type;
  String get phoneNumber => widget.codeInfo.phone_number;
  Duration get resendTime => Duration(seconds: widget.codeInfo.timeout);
  final _textEditingController = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    _textEditingController.dispose();
  }

  @override
  void initState() {
    super.initState();
    otpLenght ??= codeType.authenticationCodeTypeSms?.length;
    otpLenght ??= codeType.authenticationCodeTypeTelegramMessage?.length;
    otpLenght ??= codeType.authenticationCodeTypeFragment?.length;
    otpLenght ??= codeType.authenticationCodeTypeCall?.length;
    otpLenght ??= codeType.authenticationCodeTypeMissedCall?.length;
    otpLenght ??= codeType.authenticationCodeTypeFlashCall?.pattern.length;
    logger.fine(widget.codeInfo.toString());

    messages = switch (codeType.runtimeType) {
      t.AuthenticationCodeTypeCall => [
          'A code is delivered via a phone call',
        ],
      t.AuthenticationCodeTypeFlashCall => [
          'A code is delivered via a phone call.',
          'Enter the missed call number.',
          codeType.authenticationCodeTypeFlashCall!.pattern
        ],
      t.AuthenticationCodeTypeFragment => [
          'A code is delivered to https://fragment.com.',
        ],
      t.AuthenticationCodeTypeMissedCall => [
          'A code is delivered via a missed call.',
          'Enter last $otpLenght digit of that missed call number.'
              'starting with ${codeType.authenticationCodeTypeMissedCall?.phone_number_prefix}',
        ],
      t.AuthenticationCodeTypeSms => [
          'A code is delivered via an SMS message.'
        ],
      t.AuthenticationCodeTypeTelegramMessage => [
          'A code is delivered to other Telegram app.'
        ],
      _ => ['']
    };

    // if (codeType is t.AuthenticationCodeTypeMissedCall) {
    //   var prefix =
    //       codeType.authenticationCodeTypeMissedCall!.phone_number_prefix;
    //   _country = countries
    //       .where((element) => prefix == "+${element.fullCountryCode}")
    //       .first;
    // }
  }

  String? get hintText => codeType.authenticationCodeTypeFlashCall?.pattern;

  void _submitCode(String code) {
    context.read<AuthBloc>().add(AuthCodeAquiredEvent(code));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthStateCodeInvalid) {
          _textEditingController.clear();
          return;
        }
        state.doRoute(context);
      },
      builder: (context, state) {
        String? errorText;
        if (state is AuthStateCodeInvalid) {
          errorText = state.error.message;
        }
        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                // crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ...messages.map((e) => Text(e, textAlign: TextAlign.center)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(phoneNumber),
                      IconButton(
                        onPressed: showEditNumberAlert,
                        icon: const Icon(Icons.edit),
                        tooltip: 'edit',
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (codeType is t.AuthenticationCodeTypeSms ||
                      codeType is t.AuthenticationCodeTypeTelegramMessage ||
                      codeType is t.AuthenticationCodeTypeFragment ||
                      codeType is t.AuthenticationCodeTypeMissedCall ||
                      codeType is t.AuthenticationCodeTypeCall)
                    OtpField(
                      errorText: errorText,
                      lenght: otpLenght!,
                      controller: _textEditingController,
                      onCompleted: _submitCode,
                    ),
                  if (codeType is t.AuthenticationCodeTypeFlashCall)
                    PhoneNumberField(
                      errorText: errorText,
                      hintText: hintText,
                      onValidated: _submitCode,
                      validator: (value) {
                        return value.length == otpLenght ? null : '';
                      },
                      controller: _textEditingController,
                    )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void showEditNumberAlert() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Is this the correct number?",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          content: Text(
            phoneNumber,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                context.replace("${LoginPhoneNumberPage.path}#edit");
                Navigator.maybeOf(context)?.maybePop();
              },
              child: const Text('edit'),
            ),
          ],
        );
      },
    );
  }
}
