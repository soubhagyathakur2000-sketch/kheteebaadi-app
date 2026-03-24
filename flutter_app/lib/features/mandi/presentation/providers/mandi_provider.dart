import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kheteebaadi/core/di/injection.dart';
import 'package:kheteebaadi/features/mandi/data/datasources/mandi_local_datasource.dart';
import 'package:kheteebaadi/features/mandi/data/datasources/mandi_remote_datasource.dart';
import 'package:kheteebaadi/features/mandi/data/repositories/mandi_repository_impl.dart';
import 'package:kheteebaadi/features/mandi/domain/entities/mandi_price_entity.dart';
import 'package:kheteebaadi/features/mandi/domain/repositories/mandi_repository.dart';
import 'package:kheteebaadi/features/mandi/domain/usecases/get_mandi_prices_usecase.dart';

// Data source providers
final mandiRemoteDataSourceProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MandiRemoteDataSourceImpl(apiClient: apiClient);
});

final mandiLocalDataSourceProvider = FutureProvider((ref) async {
  final database = await ref.watch(appDatabaseProvider.future);
  return MandiLocalDataSourceImpl(database: database);
});

// Repository provider
final mandiRepositoryProvider = FutureProvider<MandiRepository>((ref) async {
  final remote = ref.watch(mandiRemoteDataSourceProvider);
  final local = await ref.watch(mandiLocalDataSourceProvider.future);
  return MandiRepositoryImpl(
    remoteDataSource: remote,
    localDataSource: local,
  );
});

// Use case provider
final getMandiPricesUseCaseProvider = FutureProvider((ref) async {
  final repository = await ref.watch(mandiRepositoryProvider.future);
  return GetMandiPricesUseCase(repository: repository);
});

// State for mandi prices list
class MandiPricesState {
  final List<MandiPriceEntity> prices;
  final bool isLoading;
  final String? error;
  final bool isCached;
  final int currentPage;

  MandiPricesState({
    this.prices = const [],
    this.isLoading = false,
    this.error,
    this.isCached = false,
    this.currentPage = 1,
  });

  MandiPricesState copyWith({
    List<MandiPriceEntity>? prices,
    bool? isLoading,
    String? error,
    bool? isCached,
    int? currentPage,
  }) {
    return MandiPricesState(
      prices: prices ?? this.prices,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isCached: isCached ?? this.isCached,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

// Notifier for mandi prices
class MandiPricesNotifier extends StateNotifier<MandiPricesState> {
  final GetMandiPricesUseCase _useCase;
  final String _regionId;

  MandiPricesNotifier({
    required GetMandiPricesUseCase useCase,
    required String regionId,
  })  : _useCase = useCase,
        _regionId = regionId,
        super(MandiPricesState());

  Future<void> loadPrices({int page = 1}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _useCase(
      _regionId,
      page: page,
      limit: 20,
    );

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
        isCached: false,
      ),
      (prices) => state = state.copyWith(
        isLoading: false,
        prices: prices,
        isCached: false,
        currentPage: page,
      ),
    );
  }

  Future<void> searchCrops(String query) async {
    if (query.isEmpty) {
      state = state.copyWith(prices: [], isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    final result = await _useCase.searchCrops(query);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (prices) => state = state.copyWith(
        isLoading: false,
        prices: prices,
      ),
    );
  }

  Future<void> refresh() async {
    await loadPrices(page: 1);
  }
}

// Provider factory for mandi prices
final mandiPricesProvider = StateNotifierProvider.family<
    MandiPricesNotifier,
    MandiPricesState,
    String>((ref, regionId) async {
  final useCase = await ref.watch(getMandiPricesUseCaseProvider.future);
  final notifier = MandiPricesNotifier(
    useCase: useCase,
    regionId: regionId,
  );
  await notifier.loadPrices();
  return notifier;
});

// Search crops provider
final searchCropsProvider =
    StateNotifierProvider.family<MandiPricesNotifier, MandiPricesState, String>(
        (ref, regionId) async {
  final useCase = await ref.watch(getMandiPricesUseCaseProvider.future);
  return MandiPricesNotifier(
    useCase: useCase,
    regionId: regionId,
  );
});
