import 'package:flutter/material.dart';
import 'package:intl_phone_field/countries.dart';

import 'country_search_delegate.dart';

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
  void dispose() {
    super.dispose();
    _textEditingController.dispose();
  }

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
          context: context,
          delegate: CountrySearchDelegate(),
        );
        setState(() {
          _selectedCountry = result ?? _selectedCountry;
          _textEditingController.value =
              TextEditingValue(text: _selectedCountry.name);
          widget.onCountryChanged?.call(_selectedCountry);
        });
        if (context.mounted) {
          FocusScope.of(context).nextFocus();
        }
      },
      readOnly: true,
      textInputAction: TextInputAction.next,
    );
  }
}
