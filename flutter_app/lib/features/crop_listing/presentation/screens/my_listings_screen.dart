import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kheteebaadi/core/theme/app_theme.dart';
import 'package:kheteebaadi/features/crop_listing/domain/entities/crop_listing.dart';
import 'package:kheteebaadi/features/crop_listing/presentation/providers/crop_listing_provider.dart';
import 'package:kheteebaadi/features/crop_listing/presentation/screens/crop_listing_screen.dart';

class MyListingsScreen extends ConsumerStatefulWidget {
  final String userId;
  final String villageId;

  const MyListingsScreen({
    Key? key,
    required this.userId,
    required this.villageId,
  }) : super(key: key);

  @override
  ConsumerState<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends ConsumerState<MyListingsScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(userListingsProvider(widget.userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Crop Listings'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(userListingsProvider(widget.userId));
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: listingsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stackTrace) => _buildErrorState(error),
          data: (listings) => _buildListingsList(listings),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CropListingScreen(
                userId: widget.userId,
                villageId: widget.villageId,
              ),
            ),
          );
        },
        backgroundColor: AppTheme.primaryGreen,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
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
              'Failed to load listings',
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
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.refresh(userListingsProvider(widget.userId));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListingsList(List<CropListing> listings) {
    if (listings.isEmpty) {
      return _buildEmptyState();
    }

    // Group listings by status
    final draftListings = listings
        .where((l) => l.status == CropListingStatus.draft)
        .toList();
    final pendingListings = listings
        .where((l) => l.status == CropListingStatus.pendingSync)
        .toList();
    final syncedListings = listings
        .where((l) => l.status == CropListingStatus.synced)
        .toList();
    final soldListings =
        listings.where((l) => l.status == CropListingStatus.sold).toList();

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        if (draftListings.isNotEmpty) ...[
          _buildSectionHeader('Drafts', draftListings.length),
          ...draftListings.map((l) => _buildListingCard(l)),
          const SizedBox(height: 20),
        ],
        if (pendingListings.isNotEmpty) ...[
          _buildSectionHeader('Pending Sync', pendingListings.length),
          ...pendingListings.map((l) => _buildListingCard(l)),
          const SizedBox(height: 20),
        ],
        if (syncedListings.isNotEmpty) ...[
          _buildSectionHeader('Published', syncedListings.length),
          ...syncedListings.map((l) => _buildListingCard(l)),
          const SizedBox(height: 20),
        ],
        if (soldListings.isNotEmpty) ...[
          _buildSectionHeader('Sold', soldListings.length),
          ...soldListings.map((l) => _buildListingCard(l)),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryGreenLight.withOpacity(0.1),
              ),
              child: const Icon(
                Icons.grass,
                size: 56,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Listings Yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Sell your crop by creating your first listing',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'OpenSans',
                color: AppTheme.neutralGray,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CropListingScreen(
                      userId: widget.userId,
                      villageId: widget.villageId,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Listing'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'OpenSans',
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'OpenSans',
                color: AppTheme.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingCard(CropListing listing) {
    final statusColor = _getStatusColor(listing.status);
    final statusIcon = _getStatusIcon(listing.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.cropName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'OpenSans',
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Type: ${listing.cropType}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'OpenSans',
                          color: AppTheme.neutralGray,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    border: Border.all(color: statusColor),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        listing.status.displayName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'OpenSans',
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Quantity and price row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quantity',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'OpenSans',
                          color: AppTheme.neutralGray,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${listing.quantityQuintals.toStringAsFixed(1)} Q',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'OpenSans',
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Expected Price',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'OpenSans',
                          color: AppTheme.neutralGray,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        listing.expectedPricePerQuintal != null
                            ? '₹${listing.expectedPricePerQuintal!.toStringAsFixed(0)}/Q'
                            : 'Not set',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'OpenSans',
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Images',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'OpenSans',
                          color: AppTheme.neutralGray,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${listing.imagePaths.length}/3',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'OpenSans',
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Created date
            Text(
              'Created: ${_formatDate(listing.createdAt)}',
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'OpenSans',
                color: AppTheme.neutralGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(CropListingStatus status) {
    switch (status) {
      case CropListingStatus.draft:
        return AppTheme.neutralGray;
      case CropListingStatus.pendingSync:
        return AppTheme.warningOrange;
      case CropListingStatus.synced:
        return AppTheme.successGreen;
      case CropListingStatus.sold:
        return AppTheme.primaryGreen;
    }
  }

  IconData _getStatusIcon(CropListingStatus status) {
    switch (status) {
      case CropListingStatus.draft:
        return Icons.edit;
      case CropListingStatus.pendingSync:
        return Icons.cloud_upload;
      case CropListingStatus.synced:
        return Icons.check_circle;
      case CropListingStatus.sold:
        return Icons.done_all;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
