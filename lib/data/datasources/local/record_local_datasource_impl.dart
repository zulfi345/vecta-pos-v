import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../core/common/result.dart';
import '../../../core/services/database/database_config.dart';
import '../../../core/services/database/database_service.dart';
import '../interfaces/record_datasource.dart';

class RecordLocalDatasourceImpl implements RecordDatasource {
  final DatabaseService _databaseService;

  RecordLocalDatasourceImpl(this._databaseService);

  @override
  Future<Result<List<Map<String, dynamic>>>> getRecords(String userId, String store) async {
    try {
      final rows = await _databaseService.database.query(
        DatabaseConfig.recordTableName,
        columns: ['data'],
        where: 'userId = ? AND store = ?',
        whereArgs: [userId, store],
        orderBy: 'rowid DESC',
      );

      final records = rows.map((row) => Map<String, dynamic>.from(jsonDecode(row['data'] as String) as Map)).toList();

      return Result.success(data: records);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> upsertRecord(String userId, String store, Map<String, dynamic> record) async {
    try {
      final id = '${record['id']}';

      final values = {
        'data': jsonEncode(record),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      final updated = await _databaseService.database.update(
        DatabaseConfig.recordTableName,
        values,
        where: 'userId = ? AND store = ? AND id = ?',
        whereArgs: [userId, store, id],
      );

      if (updated == 0) {
        await _databaseService.database.insert(
          DatabaseConfig.recordTableName,
          {'userId': userId, 'store': store, 'id': id, ...values},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> deleteRecord(String userId, String store, String id) async {
    try {
      await _databaseService.database.delete(
        DatabaseConfig.recordTableName,
        where: 'userId = ? AND store = ? AND id = ?',
        whereArgs: [userId, store, id],
      );

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }
}
