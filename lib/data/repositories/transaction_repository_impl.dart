import '../../core/common/result.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/local/transaction_local_datasource_impl.dart';
import '../models/transaction_model.dart';

class TransactionRepositoryImpl extends TransactionRepository {
  final TransactionLocalDatasourceImpl transactionLocalDatasource;

  TransactionRepositoryImpl({required this.transactionLocalDatasource});

  @override
  Future<Result<int>> syncAllUserTransactions(String userId) async => Result.success(data: 0);

  @override
  Future<Result<List<TransactionEntity>>> getUserTransactions(String userId,
      {String orderBy = 'createdAt', String sortBy = 'DESC', int limit = 10, int? offset, String? contains}) async {
    final r = await transactionLocalDatasource.getUserTransactions(userId,
        orderBy: orderBy, sortBy: sortBy, limit: limit, offset: offset, contains: contains);
    if (r.isFailure) return Result.failure(error: r.error!);
    return Result.success(data: r.data!.map((e) => e.toEntity()).toList());
  }

  @override
  Future<Result<TransactionEntity?>> getTransaction(int transactionId) async {
    final r = await transactionLocalDatasource.getTransaction(transactionId);
    if (r.isFailure) return Result.failure(error: r.error!);
    return Result.success(data: r.data?.toEntity());
  }

  @override
  Future<Result<int>> createTransaction(TransactionEntity transaction) =>
      transactionLocalDatasource.createTransaction(TransactionModel.fromEntity(transaction));

  @override
  Future<Result<void>> updateTransaction(TransactionEntity transaction) => transactionLocalDatasource
      .updateTransaction(TransactionModel.fromEntity(transaction)..updatedAt = DateTime.now().toIso8601String());

  @override
  Future<Result<void>> deleteTransaction(int transactionId) =>
      transactionLocalDatasource.deleteTransaction(transactionId);
}
