import 'package:flutter/material.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:intl_phone_field/phone_number.dart' as p;

import 'country_field.dart';
import 'country_search_delegate.dart';
import 'phone_number_field.dart';

class CountryAndPhoneNumberField extends StatefulWidget {
  const CountryAndPhoneNumberField(
      {super.key,
      required this.onValidated,
      this.onChanged,
      this.country,
      this.errorText});
  final void Function(PhoneNumber value) onValidated;
  final void Function(PhoneNumber value)? onChanged;
  final String? errorText;

  final String? country;
  @override
  State<CountryAndPhoneNumberField> createState() =>
      CountryAndPhoneNumberFieldState();
}

class CountryAndPhoneNumberFieldState
    extends State<CountryAndPhoneNumberField> {
  var _selectedCountry = getCountryFromCode('IN')!;
  final _textController = TextEditingController();
  @override
  void dispose() {
    super.dispose();
    _textController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // widget.onChanged?.call(
    //   PhoneNumber(country: _selectedCountry, number: _textController.text),
    // );
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        CountryField(
          country: widget.country ?? 'IN',
          onCountryChanged: (country) =>
              setState(() => _selectedCountry = country),
        ),
        const SizedBox(height: 10),
        PhoneNumberField(
          errorText: widget.errorText,
          onChanged: (value) {
            if (value.isEmpty) return;
            widget.onChanged?.call(
              PhoneNumber(country: _selectedCountry, number: value),
            );
          },
          onValidated: (value) => widget.onValidated(
            PhoneNumber(
              country: _selectedCountry,
              number: value,
            ),
          ),
          controller: _textController,
          country: _selectedCountry,
        ),
      ],
    );
  }
}

class PhoneNumber {
  final Country country;
  final String number;

  PhoneNumber({required this.country, required this.number});

  String get completeNumber => "+${country.fullCountryCode}$number";

  factory PhoneNumber.fromCompleteNumber(String completeNumber) {
    var pn = p.PhoneNumber.fromCompleteNumber(completeNumber: completeNumber);
    var country = pn.country;
    if (pn.country.name == '?') {
      country = anonymousNumberCountry;
    }
    return PhoneNumber(country: country, number: pn.number);
  }
}
