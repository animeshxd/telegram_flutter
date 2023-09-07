import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:pinput/pinput.dart';
import 'package:tdffi/td.dart' as t;

GoRouter routers = GoRouter(
  debugLogDiagnostics: true,
  routes: [
    GoRoute(
      path: '/',
      redirect: (context, state) => '/login/otp',
    ),
    GoRoute(
      path: '/login',
      routes: [
        GoRoute(
          path: 'phoneNumber',
          builder: (context, state) => const LoginPhoneNumberPage(),
        ),
        GoRoute(
          path: 'botToken',
          builder: (context, state) => const LoginAsBotPage(),
        ),
        GoRoute(
          path: 'otp',
          builder: (context, state) {
            return OTPPage(
              codeType: t.AuthenticationCodeTypeMissedCall(
                  length: 5, phone_number_prefix: '+91'),
              phoneNumber: '+91 1234567890',
            );
          },
        )
      ],
      redirect: (context, state) {
        if (state.fullPath == '/login') {
          return '/login/phoneNumber';
        }
        return null;
      },
    ),
  ],
  // refreshListenable: context.read<>,
  // redirect: (context, state) {
  //  if(context.read<AuthBloc>()) {}
  //   return null;
  // },
);

void main(List<String> args) {
  runApp(MaterialApp.router(
    routerConfig: routers,
    debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
  ));
}

class LoginPhoneNumberPage extends StatefulWidget {
  const LoginPhoneNumberPage({super.key});

  @override
  State<LoginPhoneNumberPage> createState() => _LoginPhoneNumberPageState();
}

class _LoginPhoneNumberPageState extends State<LoginPhoneNumberPage> {
  var _selectedCountry = getCountryFromCode('IN')!;
  final _textController = TextEditingController();
  bool _phoneIsValidated = false;
  bool _isSending = false;

  String get getFullNumber =>
      "+${_selectedCountry.fullCountryCode}${_textController.text}";

  void _onFormValidated(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Is this the correct number?"),
          titleTextStyle: const TextStyle(inherit: false),
          content: Text(
            "+${_selectedCountry.fullCountryCode} ${_textController.text}",
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
                setState(() => _isSending = true);
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
    return Scaffold(
      appBar: AppBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: !_isSending && _phoneIsValidated
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
            CountryField(
              country: 'IN',
              onCountryChanged: (country) =>
                  setState(() => _selectedCountry = country),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _textController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: true,
              decoration: InputDecoration(
                prefix: Text("+${_selectedCountry.fullCountryCode}  |  "),
                border: const OutlineInputBorder(),
                focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white)),
                hintText:
                    '01234567898765'.substring(0, _selectedCountry.maxLength),
                label: const Text("Phone Number"),
              ),
              maxLength: _selectedCountry.maxLength,
              onChanged: (value) {
                if (value.isEmpty) return;
                setState(() => _phoneIsValidated =
                    value.length >= _selectedCountry.minLength);
              },
            ),
            const SizedBox(
              height: 5,
            ),
            TextButton(
              onPressed: () {
                context.go('/login/botToken');
              },
              child: const Text('Login with Bot Token'),
            )
          ],
        ),
      ),
    );
  }
}

var _countries = Map.fromEntries(countries.map((e) => MapEntry(e.code, e)));
Country? getCountryFromCode(String country) {
  if (country.isEmpty) {
    return const Country(
      name: 'Anonymous Number',
      flag: '🏴‍☠️',
      code: 'XX',
      dialCode: '888',
      nameTranslations: {},
      minLength: 8,
      maxLength: 8,
    );
  }
  return _countries[country];
}

class CountryField extends StatefulWidget {
  final String country;
  final Function(Country country)? onCountryChanged;
  const CountryField({
    super.key,
    required this.country,
    this.onCountryChanged,
  });

  @override
  State<CountryField> createState() => _CountryFieldState();
}

class _CountryFieldState extends State<CountryField> {
  late Country _selectedCountry = getCountryFromCode(widget.country)!;
  late final _textEditingController =
      TextEditingController(text: _selectedCountry.name);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _textEditingController,
      decoration: InputDecoration(
        prefix: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            _selectedCountry.flag,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        suffixIcon: const Icon(Icons.navigate_next),
        border: const OutlineInputBorder(),
        label: const Text('Country'),
      ),
      onTap: () async {
        var result = await showSearch<Country>(
            context: context, delegate: CountrySearchDelegate());
        setState(() {
          _selectedCountry = result ?? _selectedCountry;
          _textEditingController.value =
              TextEditingValue(text: _selectedCountry.name);
          widget.onCountryChanged?.call(_selectedCountry);
        });
      },
      readOnly: true,
    );
  }
}

class CountrySearchDelegate extends SearchDelegate<Country> {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return null;
  }

  @override
  Widget buildResults(BuildContext context) {
    var query_ = RegExp(query, caseSensitive: false);
    var result = countries
        .where((element) =>
            ((query.length > 2 && element.name.contains(query_)) ||
                element.fullCountryCode.contains(query_)) ||
            element.code.contains(query_))
        .toList();

    if (((query.length > 2 && 'Anonymous Number'.contains(query_)) ||
            'XX'.contains(query_)) ||
        '888'.contains(query_)) {
      result.add(
        const Country(
          name: 'Anonymous Number',
          flag: '🏴‍☠️',
          code: 'XX',
          dialCode: '888',
          nameTranslations: {},
          minLength: 8,
          maxLength: 8,
        ),
      );
    }
    return ListView.separated(
      itemBuilder: (context, index) {
        var country = result[index];
        return listTileFromCode(context, country);
      },
      separatorBuilder: (context, index) => const Divider(),
      itemCount: result.length,
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return ListView.separated(
      itemBuilder: (context, index) {
        late Country country;
        if (index == 0) {
          country = const Country(
            name: 'Anonymous Number',
            flag: '🏴‍☠️',
            code: 'XX',
            dialCode: '888',
            nameTranslations: {},
            minLength: 8,
            maxLength: 8,
          );
        } else {
          country = countries[index + 1];
        }
        return listTileFromCode(context, country);
      },
      separatorBuilder: (context, index) => const Divider(),
      itemCount: countries.length + 1,
    );
  }

  ListTile listTileFromCode(BuildContext context, Country country) {
    return ListTile(
      onTap: () => close(context, country),
      subtitle: Text(country.code),
      leading: Text(
        country.flag,
        style: const TextStyle(fontSize: 15),
      ),
      title: Text(
        country.name,
        style: const TextStyle(fontSize: 15),
      ),
      trailing: Text('+${country.fullCountryCode}'),
    );
  }
}

class LoginAsBotPage extends StatefulWidget {
  const LoginAsBotPage({super.key});

  @override
  State<LoginAsBotPage> createState() => _LoginAsBotPageState();
}

class _LoginAsBotPageState extends State<LoginAsBotPage> {
  final _botTokenController = TextEditingController();
  bool _isBotTokenValidated = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _botTokenController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                label: Text('Bot Token'),
              ),
              onChanged: (value) {
                setState(() => _isBotTokenValidated = value.length > 42);
              },
            ),
            const SizedBox(
              height: 15,
            ),
            TextButton(
              onPressed: () {
                context.go('/login/phoneNumber');
              },
              child: const Text('Login with Phone Number'),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isBotTokenValidated ? () {} : null,
        child: const Icon(Icons.navigate_next),
      ),
    );
  }
}

class OTPPage extends StatefulWidget {
  final t.AuthenticationCodeType codeType;
  final String phoneNumber;
  const OTPPage({super.key, required this.codeType, required this.phoneNumber});

  @override
  State<OTPPage> createState() => _OTPPageState();
}

class _OTPPageState extends State<OTPPage> {
  int? otpLenght;
  List<String> messages = [];

  @override
  void initState() {
    super.initState();
    otpLenght ??= widget.codeType.authenticationCodeTypeSms?.length;
    otpLenght ??= widget.codeType.authenticationCodeTypeTelegramMessage?.length;
    otpLenght ??= widget.codeType.authenticationCodeTypeFragment?.length;
    otpLenght ??= widget.codeType.authenticationCodeTypeCall?.length;
    otpLenght ??= widget.codeType.authenticationCodeTypeMissedCall?.length;

    messages = switch (widget.codeType.runtimeType) {
      t.AuthenticationCodeTypeCall => [
          'A code is delivered via a phone call',
        ],
      t.AuthenticationCodeTypeFlashCall => [
          'A code is delivered via a phone call.',
          'Enter the missed call number',
        ],
      t.AuthenticationCodeTypeFragment => [
          'A code is delivered to https://fragment.com.',
        ],
      t.AuthenticationCodeTypeMissedCall => [
          'A code is delivered via a missed call.',
          'Enter last $otpLenght digit of that missed call number '
              'starting with ${widget.codeType.authenticationCodeTypeMissedCall?.phone_number_prefix}',
        ],
      t.AuthenticationCodeTypeSms => [
          'A code is delivered via an SMS message.'
        ],
      t.AuthenticationCodeTypeTelegramMessage => [
          'A code is delivered to other Telegram app.'
        ],
      _ => ['']
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(onPressed: () {}),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            // crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ...messages.map(
                (e) => Text(
                  e,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Text(widget.phoneNumber),
              const SizedBox(
                height: 10,
              ),
              if (widget.codeType is t.AuthenticationCodeTypeSms ||
                  widget.codeType is t.AuthenticationCodeTypeTelegramMessage ||
                  widget.codeType is t.AuthenticationCodeTypeFragment ||
                  widget.codeType is t.AuthenticationCodeTypeMissedCall ||
                  widget.codeType is t.AuthenticationCodeTypeCall)
                OtpField(lenght: otpLenght!)
            ],
          ),
        ),
      ),
    );
  }
}

class OtpField extends StatelessWidget {
  const OtpField({
    Key? key,
    this.lenght = 4,
    this.onCompleted,
  }) : super(key: key);

  final int lenght;
  final FutureOr<void> Function(String value)? onCompleted;

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var width = size.width / lenght;
    var pinTheme = PinTheme(
      // padding: EdgeInsets.all(10),
      width: size.width < 260 ? width : 30,
      height: size.width < 260 ? width : 40,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white38),
        borderRadius: BorderRadius.circular(2),
      ),
    );
    var focusedTheme = pinTheme.copyBorderWith(
      border: Border.all(
        color: Theme.of(context).colorScheme.secondary,
      ),
    );
    // debugPrint(size.width.toString());))
    return Pinput(
      autofocus: true,
      length: lenght,
      defaultPinTheme: pinTheme,
      focusedPinTheme: focusedTheme,
      submittedPinTheme: focusedTheme,
      onCompleted: onCompleted,
    );
  }
}
