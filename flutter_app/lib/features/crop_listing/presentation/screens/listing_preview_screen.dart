import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kheteebaadi/core/theme/app_theme.dart';
import 'package:kheteebaadi/features/crop_listing/presentation/providers/crop_listing_provider.dart';

class ListingPreviewScreen extends ConsumerStatefulWidget {
  final String listingId;
  final String userId;

  const ListingPreviewScreen({
    Key? key,
    required this.listingId,
    required this.userId,
  }) : super(key: key);

  @override
  ConsumerState<ListingPreviewScreen> createState() =>
      _ListingPreviewScreenState();
}

class _ListingPreviewScreenState extends ConsumerState<ListingPreviewScreen> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final listingAsync = ref.watch(cropListingByIdProvider(widget.listingId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Listing'),
        elevation: 0,
      ),
      body: listingAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppTheme.errorRed,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load listing',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'OpenSans',
                    color: AppTheme.neutralGray,
                  ),
                ),
              ],
            ),
          ),
        ),
        data: (listing) {
          if (listing == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.not_found,
                    size: 64,
                    color: AppTheme.neutralGray,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Listing not found',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image carousel
                if (listing.imagePaths.isNotEmpty)
                  _buildImageCarousel(listing.imagePaths),

                // Listing details
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Crop info
                      _buildDetailCard(
                        title: 'Crop Information',
                        children: [
                          _buildDetailRow('Crop Type', listing.cropType),
                          const Divider(),
                          _buildDetailRow('Crop Name', listing.cropName),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Quantity and Price
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailCard(
                              title: 'Quantity',
                              children: [
                                _buildDetailRow(
                                  'Quintals',
                                  listing.quantityQuintals.toString(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDetailCard(
                              title: 'Expected Price',
                              children: [
                                _buildDetailRow(
                                  'Per Quintal',
                                  listing.expectedPricePerQuintal != null
                                      ? '₹${listing.expectedPricePerQuintal!.toStringAsFixed(2)}'
                                      : 'Not set',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(listing.status).withOpacity(0.1),
                          border: Border.all(
                            color: _getStatusColor(listing.status),
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Status: ${listing.status.displayName}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'OpenSans',
                            color: _getStatusColor(listing.status),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description
                      if (listing.description != null &&
                          listing.description!.isNotEmpty) ...[
                        _buildDetailCard(
                          title: 'Description',
                          children: [
                            Text(
                              listing.description!,
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'OpenSans',
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.edit),
                              label: const Text('Edit'),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isSubmitting
                                  ? null
                                  : () => _confirmSubmit(context),
                              icon: _isSubmitting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Icon(Icons.check_circle),
                              label: const Text('Confirm & Submit'),
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageCarousel(List<String> imagePaths) {
    return SizedBox(
      height: 300,
      child: PageView.builder(
        itemCount: imagePaths.length,
        itemBuilder: (context, index) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                File(imagePaths[index]),
                fit: BoxFit.cover,
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${index + 1}/${imagePaths.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'OpenSans',
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderGray),
        borderRadius: BorderRadius.circular(8),
        color: AppTheme.lightGray,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'OpenSans',
              color: AppTheme.neutralGray,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontFamily: 'OpenSans',
              color: AppTheme.neutralGray,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'OpenSans',
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(dynamic status) {
    final statusStr = status.toString().toLowerCase();
    if (statusStr.contains('synced')) return AppTheme.successGreen;
    if (statusStr.contains('pending')) return AppTheme.warningOrange;
    if (statusStr.contains('sold')) return AppTheme.primaryGreen;
    return AppTheme.neutralGray;
  }

  void _confirmSubmit(BuildContext context) async {
    setState(() => _isSubmitting = true);

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Listing submitted successfully!'),
          backgroundColor: AppTheme.successGreen,
          duration: const Duration(seconds: 2),
        ),
      );

      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.errorRed,
        ),
      );

      setState(() => _isSubmitting = false);
    }
  }
}
