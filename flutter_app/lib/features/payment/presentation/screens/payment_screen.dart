import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:kheteebaadi/core/theme/app_theme.dart';
import 'package:kheteebaadi/core/constants/app_constants.dart';
import 'package:kheteebaadi/features/store/domain/entities/cart_item.dart';
import 'package:kheteebaadi/features/store/presentation/providers/cart_provider.dart';
import 'package:kheteebaadi/features/payment/presentation/providers/payment_provider.dart';
import 'package:kheteebaadi/features/payment/presentation/screens/payment_pending_screen.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final double cartTotal;
  final List<CartItem> cartItems;

  const PaymentScreen({
    Key? key,
    required this.cartTotal,
    required this.cartItems,
  }) : super(key: key);

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  late Razorpay _razorpay;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeRazorpay();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  Future<void> _initiatePayment() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final orderId = _generateOrderId();

      // Initiate payment through repository
      await ref
          .read(paymentNotifierProvider.notifier)
          .initiatePayment(
            orderId: orderId,
            amount: widget.cartTotal,
          )
          .then((_) {
            _openCheckout(orderId);
          });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Failed to initiate payment: $e';
      });
    }
  }

  void _openCheckout(String orderId) {
    final options = {
      'key': AppConstants.razorpayKeyId,
      'amount': (widget.cartTotal * 100).toInt(), // Amount in paise
      'name': 'Kheteebaadi Store',
      'description': 'Agrochemical Products Order',
      'order_id': orderId,
      'prefill': {
        'contact': '9999999999', // Would be user's phone in real app
        'email': 'user@example.com', // Would be user's email in real app
      },
      'theme': {
        'color': AppTheme.primaryGreen.value.toRadixString(16).padLeft(8, '0'),
      },
      'image': '', // Your logo URL
      'retry': {
        'enabled': true,
        'max_count': 3,
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Failed to open checkout: $e';
      });
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    setState(() {
      _isProcessing = false;
    });

    ref
        .read(paymentNotifierProvider.notifier)
        .onPaymentSuccess(
          razorpayPaymentId: response.paymentId ?? '',
          razorpayOrderId: response.orderId ?? '',
          razorpaySignature: response.signature ?? '',
        )
        .then((_) {
          // Clear cart and navigate to success
          ref.read(cartProvider.notifier).clearCart();

          Navigator.of(context).pushReplacementNamed('/order-success');
        })
        .catchError((e) {
          setState(() {
            _errorMessage = 'Payment verification failed: $e';
          });

          // Navigate to pending screen for recovery
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => PaymentPendingScreen(
                razorpayOrderId: response.orderId ?? '',
              ),
            ),
          );
        });
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() {
      _isProcessing = false;
      _errorMessage =
          'Payment failed: ${response.code ?? 'Unknown error'} - ${response.message}';
    });

    ref
        .read(paymentNotifierProvider.notifier)
        .onPaymentFailure(
          errorCode: response.code ?? 'UNKNOWN_ERROR',
          errorDescription: response.message ?? 'Unknown error',
        );

    // Show error dialog
    _showErrorDialog(
      'Payment Failed',
      response.message ?? 'Payment was not successful. Please try again.',
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ref
        .read(paymentNotifierProvider.notifier)
        .onExternalWalletSelected(
          walletName: response.walletName ?? 'Unknown',
        );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _generateOrderId() {
    return 'ORD-${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: AppTheme.primaryGreen,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order summary
            Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Items: ${widget.cartItems.length}'),
                      Text(
                        '${widget.cartItems.fold<int>(0, (sum, item) => sum + item.quantity)} units',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount:'),
                      Text(
                        '₹${widget.cartTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Order items preview
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Items in Order',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.cartItems.length,
                    itemBuilder: (context, index) {
                      final item = widget.cartItems[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item.productName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text('${item.quantity}x ₹${item.unitPrice}'),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Error message
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withOpacity(0.1),
                  border: Border.all(color: AppTheme.errorRed),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: AppTheme.errorRed,
                    fontSize: 14,
                  ),
                ),
              ),

            // Payment methods info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppTheme.primaryGreen,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Payment Methods Available',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Credit/Debit Cards, UPI, Mobile Wallets, NetBanking',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Secure payment powered by Razorpay',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Pay button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                  ),
                  onPressed: _isProcessing ? null : _initiatePayment,
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text(
                          'Pay ₹${widget.cartTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
