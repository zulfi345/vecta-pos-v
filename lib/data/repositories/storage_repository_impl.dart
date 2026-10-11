import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/common/result.dart';
import '../../domain/repositories/storage_repository.dart';

class StorageRepositoryImpl implements StorageRepository {
  @override
  Future<Result<String>> uploadUserPhoto(String imgPath) => _save(imgPath, 'users');

  @override
  Future<Result<String>> uploadProductImage(String imgPath) => _save(imgPath, 'products');

  Future<Result<String>> _save(String imgPath, String folder) async {
    try {
      final src = File(imgPath);
      if (!await src.exists()) return Result.failure(error: 'File gambar tidak ditemukan');
      final docs = await getApplicationDocumentsDirectory();
      final dir = await Directory(p.join(docs.path, 'images', folder)).create(recursive: true);
      final name = '${DateTime.now().millisecondsSinceEpoch}${p.extension(imgPath)}';
      final out = await src.copy(p.join(dir.path, name));
      return Result.success(data: out.path);
    } catch (e) {
      return Result.failure(error: e);
    }
  }
}
