import 'dart:async';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:get/get_rx/get_rx.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tdffi/client.dart';
import 'package:tdffi/td.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class DownloadProfilePhoto {
  StreamSubscription? _streamSubscription;
  final TdlibEventController tdlib;
  Database? _database;

  final state = <int, String>{}.obs;

  Future<Database> get database async => _database ??= await openDatabase(
        p.join(
          (await getApplicationCacheDirectory()).path,
          'file_info_database.db',
        ),
        version: 1,
        onCreate: (db, version) async {
          await db.execute(
            "CREATE TABLE IF NOT EXISTS file_info (id int primary key, path text not null)",
          );
        },
      );

  DownloadProfilePhoto(this.tdlib) {
    _streamSubscription = tdlib.updates
        .whereType<UpdateFile>()
        .where((event) => event.file.local.is_downloading_completed)
        .map((event) => event.file)
        .listen(_updateProfilePhotoIntoDatabase);
  }

  void downloadFile(File? file) async {
    debugPrint(file?.local.toString());
    if (file == null) return;
    if (file.local.is_downloading_completed ||
        file.local.is_downloading_active) {
      return;
    }
    await tdlib.send<File>(DownloadFile(
      file_id: file.id,
      priority: 1,
      offset: 0,
      limit: 0,
      synchronous: false,
    ));
  }

  void _updateProfilePhotoIntoDatabase(File file) async {
    if (!file.local.is_downloading_completed) return;
    state[file.id] = file.local.path;
    state.refresh();
    var db = await database;
    await db.insert(
      'file_info',
      {'id': file.id, 'path': file.local.path},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  void loadExisting() async {
    var db = await database;

    var result = (await db.query('file_info'))
        .map((e) => MapEntry(e['id'] as int, e['path'] as String))
        .where((f) => !io.File(f.value).existsSync());
    state.addEntries(result);

    var list = result.map((e) => e.key).toList();
    if (list.isEmpty) return;
    await db.delete(
      'file_info',
      where: "id in (${List.filled(list.length, '?').join(',')})",
      whereArgs: list,
    );
  }

  void dispose() async {
    (await database).close();
    _database = null;
    _streamSubscription?.cancel();
  }
}
