import '../../../core/common/result.dart';

abstract class RecordDatasource {
  Future<Result<List<Map<String, dynamic>>>> getRecords(String userId, String store);

  Future<Result<void>> upsertRecord(String userId, String store, Map<String, dynamic> record);

  Future<Result<void>> deleteRecord(String userId, String store, String id);
}
