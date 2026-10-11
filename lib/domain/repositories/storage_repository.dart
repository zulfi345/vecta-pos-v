// lib/features/auth/domain/repositories/auth_repository.dart

import 'package:flutter_pos/core/common/result.dart';

abstract class StorageRepository {
  Future<Result<String>> uploadUserPhoto(String imgPath);

  Future<Result<String?>> uploadProductImage(String imgPath);
}
