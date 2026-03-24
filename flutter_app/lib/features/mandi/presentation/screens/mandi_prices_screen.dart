import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:kheteebaadi/core/di/injection.dart';
import 'package:kheteebaadi/features/mandi/presentation/providers/mandi_provider.dart';
import 'package:kheteebaadi/features/mandi/presentation/widgets/price_card.dart';

class MandiPricesScreen extends ConsumerStatefulWidget {
  const MandiPricesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MandiPricesScreen> createState() => _MandiPricesScreenState();
}

class _MandiPricesScreenState extends ConsumerState<MandiPricesScreen> {
  late TextEditingController _searchController;
  String _selectedRegion = 'maharashtra';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() => _isSearching = query.isNotEmpty);

    if (query.isNotEmpty) {
      final notifier =
          ref.read(searchCropsProvider(_selectedRegion).notifier);
      notifier.searchCrops(query);
    } else {
      final notifier = ref.read(mandiPricesProvider(_selectedRegion).notifier);
      notifier.loadPrices();
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectionStatus = ref.watch(connectionStatusProvider);
    final isOnline = connectionStatus.maybeWhen(
      data: (status) => status.isOnline,
      orElse: () => false,
    );

    final provider =
        _isSearching && _searchController.text.isNotEmpty
            ? searchCropsProvider(_selectedRegion)
            : mandiPricesProvider(_selectedRegion);

    final mandiState = ref.watch(provider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF2E7D32),
        title: const Text('Mandi Prices'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final notifier =
              ref.read(mandiPricesProvider(_selectedRegion).notifier);
          await notifier.refresh();
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (!isOnline)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 16),
                  color: Colors.orange,
                  child: Row(
                    children: const [
                      Icon(Icons.wifi_off, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Showing cached prices',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search crops (wheat, rice, sugarcane...)',
                        hintStyle: const TextStyle(
                          color: Color(0xFFBDBDBD),
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF757575),
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() => _isSearching = false);
                                  final notifier = ref.read(
                                      mandiPricesProvider(_selectedRegion)
                                          .notifier);
                                  notifier.loadPrices();
                                },
                                child: const Icon(
                                  Icons.clear,
                                  color: Color(0xFF757575),
                                ),
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE0E0E0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE0E0E0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF2E7D32),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _RegionChip(
                            label: 'Maharashtra',
                            isSelected: _selectedRegion == 'maharashtra',
                            onTap: () {
                              setState(
                                  () => _selectedRegion = 'maharashtra');
                            },
                          ),
                          const SizedBox(width: 8),
                          _RegionChip(
                            label: 'Karnataka',
                            isSelected: _selectedRegion == 'karnataka',
                            onTap: () {
                              setState(
                                  () => _selectedRegion = 'karnataka');
                            },
                          ),
                          const SizedBox(width: 8),
                          _RegionChip(
                            label: 'Madhya Pradesh',
                            isSelected: _selectedRegion == 'mp',
                            onTap: () {
                              setState(() => _selectedRegion = 'mp');
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    mandiState.isLoading
                        ? Column(
                            children: List.generate(
                              5,
                              (_) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Shimmer.fromColors(
                                  baseColor: Colors.grey[300]!,
                                  highlightColor: Colors.grey[100]!,
                                  child: Container(
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        : mandiState.error != null
                            ? Center(
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: Color(0xFFE53935),
                                      size: 48,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      mandiState.error ?? 'Error loading prices',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : mandiState.prices.isEmpty
                                ? Center(
                                    child: Column(
                                      children: const [
                                        Icon(
                                          Icons.agriculture,
                                          color: Color(0xFF2E7D32),
                                          size: 48,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'No prices available',
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Column(
                                    children: mandiState.prices
                                        .map((price) =>
                                            PriceCard(price: price))
                                        .toList(),
                                  ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegionChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _RegionChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2E7D32) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF2E7D32) : const Color(0xFFE0E0E0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF757575),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
