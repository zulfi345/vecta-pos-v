import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../utilities/console_logger.dart';
import 'database_config.dart';

class DatabaseService {
  DatabaseService._internal();

  static final DatabaseService _instance = DatabaseService._internal();

  static DatabaseService get instance => _instance;

  late Database database;

  Future<void> init() async {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
    }

    String path = join(await getDatabasesPath(), DatabaseConfig.dbPath);

    File databaseFile = File(path);

    if (!await databaseFile.exists()) await databaseFile.create();

    database = await openDatabase(
      path,
      version: DatabaseConfig.version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  @visibleForTesting
  Future<void> initTestDatabase({required Database testDatabase}) async {
    database = testDatabase;

    await _onCreate(database, DatabaseConfig.version);
  }

  Future<void> _onCreate(Database db, int version) async {
    for (final statement in DatabaseConfig.createStatements) {
      await db.execute(statement);
    }

    await db.execute(DatabaseConfig.dropQueuedActionTable);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(DatabaseConfig.dropQueuedActionTable);
    }
  }

  Future<void> dropDatabase(String path) async {
    File databaseFile = File(path);

    if (await databaseFile.exists()) {
      await databaseFile.delete();

      cw('Database deleted successfully!');
    } else {
      ce('Database does not exist!');
    }
  }
}
