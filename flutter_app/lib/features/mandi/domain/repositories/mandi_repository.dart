import 'package:kheteebaadi/core/utils/either.dart';
import 'package:kheteebaadi/core/utils/failure.dart';
import 'package:kheteebaadi/features/mandi/domain/entities/mandi_price_entity.dart';

abstract class MandiRepository {
  Future<Either<Failure, List<MandiPriceEntity>>> getMandiPrices(
    String regionId, {
    int page = 1,
    int limit = 20,
  });
  Future<Either<Failure, List<MandiPriceEntity>>> searchCrops(String query);
  Future<Either<Failure, Map<String, dynamic>>> getMandiDetail(String mandiId);
}
