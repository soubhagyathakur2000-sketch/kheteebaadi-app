import 'package:kheteebaadi/database/app_database.dart';
import 'package:kheteebaadi/features/mandi/data/models/mandi_price_model.dart';

abstract class MandiLocalDataSource {
  Future<void> cacheMandiPrices(List<MandiPriceModel> prices);
  Future<List<MandiPriceModel>> getCachedMandiPrices(String regionId);
  Future<List<MandiPriceModel>> searchCachedPrices(String cropQuery);
  Future<void> clearExpiredCache(Duration maxAge);
  Future<void> clearAllCache();
}

class MandiLocalDataSourceImpl implements MandiLocalDataSource {
  final AppDatabase _database;

  MandiLocalDataSourceImpl({required AppDatabase database}) : _database = database;

  @override
  Future<void> cacheMandiPrices(List<MandiPriceModel> prices) async {
    final companions = prices
        .map((price) => MandiPricesCompanion(
              id: Value(price.id),
              cropName: Value(price.cropName),
              cropNameLocal: Value(price.cropNameLocal),
              pricePerQuintal: Value(price.pricePerQuintal),
              mandiName: Value(price.mandiName),
              mandiId: Value(price.mandiId),
              regionId: Value(price.regionId),
              unit: Value(price.unit),
              priceChange: Value(price.priceChange),
              fetchedAt: Value(DateTime.now()),
              isCached: const Value(true),
            ))
        .toList();

    await _database.insertOrUpdateMandiPrices(companions);
  }

  @override
  Future<List<MandiPriceModel>> getCachedMandiPrices(String regionId) async {
    final entities =
        await _database.getMandiPricesByRegion(regionId);

    return entities
        .map((entity) => MandiPriceModel(
              id: entity.id,
              cropName: entity.cropName,
              cropNameLocal: entity.cropNameLocal,
              pricePerQuintal: entity.pricePerQuintal,
              mandiName: entity.mandiName,
              mandiId: entity.mandiId,
              regionId: entity.regionId,
              updatedAt: entity.fetchedAt,
              unit: entity.unit,
              priceChange: entity.priceChange,
            ))
        .toList();
  }

  @override
  Future<List<MandiPriceModel>> searchCachedPrices(String cropQuery) async {
    final entities = await _database.searchMandiPrices(cropQuery);

    return entities
        .map((entity) => MandiPriceModel(
              id: entity.id,
              cropName: entity.cropName,
              cropNameLocal: entity.cropNameLocal,
              pricePerQuintal: entity.pricePerQuintal,
              mandiName: entity.mandiName,
              mandiId: entity.mandiId,
              regionId: entity.regionId,
              updatedAt: entity.fetchedAt,
              unit: entity.unit,
              priceChange: entity.priceChange,
            ))
        .toList();
  }

  @override
  Future<void> clearExpiredCache(Duration maxAge) async {
    final cutoffTime = DateTime.now().subtract(maxAge);
    final entities = await _database.mandiPrices.select().get();
    final expiredIds = entities
        .where((entity) => entity.fetchedAt.isBefore(cutoffTime))
        .map((entity) => entity.id)
        .toList();

    for (final id in expiredIds) {
      await _database.deleteMandiPrice(id);
    }
  }

  @override
  Future<void> clearAllCache() async {
    await _database.clearMandiPrices();
  }
}
