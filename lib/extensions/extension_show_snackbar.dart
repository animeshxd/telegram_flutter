import 'package:flutter/material.dart';

extension ShowSnackbarExt on BuildContext {
  void showSnackBar(SnackBar snackBar) {
    if (mounted) {
      ScaffoldMessenger.maybeOf(this)?.showSnackBar(snackBar);
    }
  }
}
