import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kheteebaadi/core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({Key? key}) : super(key: key);

  Future<void> _openWhatsApp(String phoneNumber) async {
    final whatsappUrl =
        'https://wa.me/$phoneNumber?text=Hello%20I%20need%20help';
    if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
      await launchUrl(Uri.parse(whatsappUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisAxisAlignment: CrossAxisAlignment.center,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildActionCard(
            context,
            icon: Icons.grass,
            label: 'Sell Crop',
            color: AppTheme.primaryGreen,
            onTap: () => context.push('/crop-listing'),
          ),
          _buildActionCard(
            context,
            icon: Icons.shopping_bag,
            label: 'Buy Inputs',
            color: AppTheme.accentOrange,
            onTap: () => context.push('/store'),
          ),
          _buildActionCard(
            context,
            icon: Icons.list_alt,
            label: 'My Orders',
            color: const Color(0xFF1976D2),
            onTap: () => context.push('/orders'),
          ),
          _buildActionCard(
            context,
            icon: Icons.phone,
            label: 'Talk to Lead',
            color: const Color(0xFF7B1FA2),
            onTap: () => _openWhatsApp('+919876543210'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
