import 'package:kheteebaadi/core/constants/api_constants.dart';
import 'package:kheteebaadi/core/utils/either.dart';
import 'package:kheteebaadi/core/utils/failure.dart';
import 'package:kheteebaadi/features/mandi/data/datasources/mandi_local_datasource.dart';
import 'package:kheteebaadi/features/mandi/data/datasources/mandi_remote_datasource.dart';
import 'package:kheteebaadi/features/mandi/domain/entities/mandi_price_entity.dart';
import 'package:kheteebaadi/features/mandi/domain/repositories/mandi_repository.dart';

class MandiRepositoryImpl implements MandiRepository {
  final MandiRemoteDataSource _remoteDataSource;
  final MandiLocalDataSource _localDataSource;

  MandiRepositoryImpl({
    required MandiRemoteDataSource remoteDataSource,
    required MandiLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  @override
  Future<Either<Failure, List<MandiPriceEntity>>> getMandiPrices(
    String regionId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final cached = await _localDataSource.getCachedMandiPrices(regionId);

      final now = DateTime.now();
      final cacheAge = now.subtract(
        Duration(minutes: ApiConstants.mandiPricesCacheTtl),
      );

      if (cached.isNotEmpty &&
          cached.first.updatedAt.isAfter(cacheAge)) {
        return Right(cached.cast<MandiPriceEntity>());
      }

      try {
        final remote = await _remoteDataSource.getMandiPrices(
          regionId,
          page: page,
          limit: limit,
        );

        if (remote.isNotEmpty) {
          await _localDataSource.cacheMandiPrices(remote);
        }

        return Right(remote.cast<MandiPriceEntity>());
      } catch (e) {
        if (cached.isNotEmpty) {
          return Right(cached.cast<MandiPriceEntity>());
        }
        rethrow;
      }
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(
        ServerFailure(message: 'Unexpected error: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, List<MandiPriceEntity>>> searchCrops(
      String query) async {
    try {
      final cached = await _localDataSource.searchCachedPrices(query);

      try {
        final remote = await _remoteDataSource.searchCrops(query);

        if (remote.isNotEmpty) {
          await _localDataSource.cacheMandiPrices(remote);
        }

        return Right(remote.cast<MandiPriceEntity>());
      } catch (e) {
        if (cached.isNotEmpty) {
          return Right(cached.cast<MandiPriceEntity>());
        }
        rethrow;
      }
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(
        ServerFailure(message: 'Unexpected error: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getMandiDetail(
      String mandiId) async {
    try {
      final remote = await _remoteDataSource.getMandiDetail(mandiId);
      return Right(remote);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(
        ServerFailure(message: 'Unexpected error: ${e.toString()}'),
      );
    }
  }
}
