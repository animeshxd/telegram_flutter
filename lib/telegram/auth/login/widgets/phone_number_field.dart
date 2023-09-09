import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/countries.dart';

class PhoneNumberField extends StatefulWidget {
  const PhoneNumberField({
    Key? key,
    required this.controller,
    this.onChanged,
    this.onValidated,
    this.errorText,
    this.country,
    this.hintText,
    this.validator,
  }) : super(key: key);

  final TextEditingController controller;
  final void Function(String value)? onChanged;
  final void Function(String value)? onValidated;
  final String? Function(String value)? validator;
  final Country? country;
  final String? errorText;
  final String? hintText;

  @override
  State<PhoneNumberField> createState() => _PhoneNumberFieldState();
}

class _PhoneNumberFieldState extends State<PhoneNumberField> {
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _errorText = widget.errorText;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      autofocus: true,
      decoration: InputDecoration(
        prefix: widget.country == null
            ? null
            : Text("+${widget.country?.fullCountryCode}  |  "),
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(),
        hintText: widget.hintText ??
            '01234567898765'.substring(0, widget.country?.maxLength),
        errorText: _errorText,
        label: const Text("Phone Number"),
      ),
      maxLength: widget.country?.maxLength,
      onChanged: (value) {
        if (value.isEmpty) return;
        widget.onChanged?.call(value);
        var error = widget.validator?.call(value);
        var country = widget.country;
        if (country == null) {
          // errorText??=
          if (error == null) {
            widget.onValidated?.call(value);
          } else {
            setState(() => _errorText = error);
          }
          return;
        }
        if (value.length >= country.minLength &&
            value.length <= country.maxLength) {
          widget.onValidated?.call(value);
        }
      },
    );
  }
}
