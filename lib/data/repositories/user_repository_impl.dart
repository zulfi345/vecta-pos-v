import '../../core/common/result.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/local/user_local_datasource_impl.dart';
import '../models/user_model.dart';

class UserRepositoryImpl extends UserRepository {
  final UserLocalDatasourceImpl userLocalDatasource;

  UserRepositoryImpl({required this.userLocalDatasource});

  @override
  Future<Result<UserEntity?>> getUser(String userId) async {
    final r = await userLocalDatasource.getUser(userId);
    if (r.isFailure) return Result.failure(error: r.error!);
    return Result.success(data: r.data?.toEntity());
  }

  @override
  Future<Result<String>> createUser(UserEntity user) => userLocalDatasource.createUser(UserModel.fromEntity(user));

  @override
  Future<Result<void>> updateUser(UserEntity user) =>
      userLocalDatasource.updateUser(UserModel.fromEntity(user)..updatedAt = DateTime.now().toIso8601String());

  @override
  Future<Result<void>> deleteUser(String userId) => userLocalDatasource.deleteUser(userId);
}
