import 'dart:io';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app.dart';

void main() {
  Logger.root.level = Level.ALL;
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
  }

  databaseFactory = databaseFactoryFfi;
  runApp(const MainApp());
}
