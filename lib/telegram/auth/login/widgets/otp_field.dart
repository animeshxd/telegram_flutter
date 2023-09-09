import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

class OtpField extends StatelessWidget {
  const OtpField({
    Key? key,
    this.lenght = 4,
    this.onCompleted,
    this.controller,
    this.errorText,
  }) : super(key: key);

  final String? errorText;
  final int lenght;
  final TextEditingController? controller;
  final void Function(String value)? onCompleted;

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var width = size.width / lenght;
    var pinTheme = PinTheme(
      // padding: EdgeInsets.all(10),
      width: size.width < 260 ? width : 30,
      height: size.width < 260 ? width : 40,
      decoration: BoxDecoration(
        border:
            Border.all(color: Theme.of(context).textTheme.bodyLarge!.color!),
        borderRadius: BorderRadius.circular(2),
      ),
    );
    var focusedTheme = pinTheme.copyBorderWith(
      border: Border.all(
        color: Theme.of(context).colorScheme.secondary,
      ),
    );
    // debugPrint(size.width.toString());))
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Pinput(
          controller: controller,
          autofocus: true,
          length: lenght,
          defaultPinTheme: pinTheme,
          focusedPinTheme: focusedTheme,
          submittedPinTheme: focusedTheme,
          onCompleted: onCompleted,
        ),
        if (errorText != null)
          Text(
            errorText!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          )
      ],
    );
  }
}
