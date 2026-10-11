import '../../core/common/result.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/local/product_local_datasource_impl.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl extends ProductRepository {
  final ProductLocalDatasourceImpl productLocalDatasource;

  ProductRepositoryImpl({required this.productLocalDatasource});

  @override
  Future<Result<int>> syncAllUserProducts(String userId) async => Result.success(data: 0);

  @override
  Future<Result<List<ProductEntity>>> getUserProducts(String userId,
      {String orderBy = 'createdAt', String sortBy = 'DESC', int limit = 10, int? offset, String? contains}) async {
    final r = await productLocalDatasource.getUserProducts(userId,
        orderBy: orderBy, sortBy: sortBy, limit: limit, offset: offset, contains: contains);
    if (r.isFailure) return Result.failure(error: r.error!);
    return Result.success(data: r.data!.map((e) => e.toEntity()).toList());
  }

  @override
  Future<Result<ProductEntity?>> getProduct(int productId) async {
    final r = await productLocalDatasource.getProduct(productId);
    if (r.isFailure) return Result.failure(error: r.error!);
    return Result.success(data: r.data?.toEntity());
  }

  @override
  Future<Result<int>> createProduct(ProductEntity product) =>
      productLocalDatasource.createProduct(ProductModel.fromEntity(product));

  @override
  Future<Result<void>> updateProduct(ProductEntity product) => productLocalDatasource
      .updateProduct(ProductModel.fromEntity(product)..updatedAt = DateTime.now().toIso8601String());

  @override
  Future<Result<void>> deleteProduct(int productId) => productLocalDatasource.deleteProduct(productId);
}
