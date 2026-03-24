import 'package:kheteebaadi/core/utils/either.dart';
import 'package:kheteebaadi/core/utils/failure.dart';
import 'package:kheteebaadi/features/mandi/domain/entities/mandi_price_entity.dart';
import 'package:kheteebaadi/features/mandi/domain/repositories/mandi_repository.dart';

class GetMandiPricesUseCase {
  final MandiRepository _repository;

  GetMandiPricesUseCase({required MandiRepository repository})
      : _repository = repository;

  Future<Either<Failure, List<MandiPriceEntity>>> call(
    String regionId, {
    int page = 1,
    int limit = 20,
  }) {
    return _repository.getMandiPrices(
      regionId,
      page: page,
      limit: limit,
    );
  }

  Future<Either<Failure, List<MandiPriceEntity>>> searchCrops(String query) {
    return _repository.searchCrops(query);
  }

  Future<Either<Failure, Map<String, dynamic>>> getMandiDetail(
      String mandiId) {
    return _repository.getMandiDetail(mandiId);
  }
}
