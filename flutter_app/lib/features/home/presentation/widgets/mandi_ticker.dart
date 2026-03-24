import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kheteebaadi/core/theme/app_theme.dart';

// Assuming you have a mandi provider with MandiPrice model
// This is a placeholder structure - adjust based on your actual mandi implementation
class MandiPrice {
  final String cropName;
  final double price;
  final double priceChange;
  final String unit;

  MandiPrice({
    required this.cropName,
    required this.price,
    required this.priceChange,
    this.unit = 'per quintal',
  });
}

class MandiTicker extends ConsumerStatefulWidget {
  const MandiTicker({Key? key}) : super(key: key);

  @override
  ConsumerState<MandiTicker> createState() => _MandiTickerState();
}

class _MandiTickerState extends ConsumerState<MandiTicker>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _autoScrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _autoScrollController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollController.repeat();
    _autoScrollController.addListener(() {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        _scrollController.jumpTo(
          _autoScrollController.value * maxScroll,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _autoScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Mock data - replace with actual mandi provider
    final mockPrices = [
      MandiPrice(
        cropName: 'Wheat',
        price: 2200,
        priceChange: 50,
      ),
      MandiPrice(
        cropName: 'Rice',
        price: 2800,
        priceChange: -40,
      ),
      MandiPrice(
        cropName: 'Maize',
        price: 1900,
        priceChange: 30,
      ),
      MandiPrice(
        cropName: 'Cotton',
        price: 5200,
        priceChange: 120,
      ),
      MandiPrice(
        cropName: 'Soybeans',
        price: 4100,
        priceChange: -60,
      ),
    ];

    return Container(
      height: 140,
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: AppTheme.primaryGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Mandi Prices',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: mockPrices.length,
              itemBuilder: (context, index) {
                final price = mockPrices[index];
                final isPositive = price.priceChange >= 0;

                return GestureDetector(
                  onTap: () => context.push('/mandi'),
                  child: Container(
                    width: 160,
                    margin: EdgeInsets.only(
                      left: index == 0 ? 16 : 8,
                      right: index == mockPrices.length - 1 ? 16 : 0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            price.cropName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₹${price.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                isPositive
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                size: 14,
                                color: isPositive
                                    ? AppTheme.successGreen
                                    : AppTheme.errorRed,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${price.priceChange.abs().toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isPositive
                                      ? AppTheme.successGreen
                                      : AppTheme.errorRed,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
