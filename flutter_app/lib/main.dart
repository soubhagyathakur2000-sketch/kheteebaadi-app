import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:kheteebaadi/core/constants/app_constants.dart';
import 'package:kheteebaadi/core/di/injection.dart';
import 'package:kheteebaadi/core/theme/app_theme.dart';
import 'package:kheteebaadi/features/auth/presentation/providers/auth_provider.dart';
import 'package:kheteebaadi/features/auth/presentation/screens/login_screen.dart';
import 'package:kheteebaadi/features/crop_listing/presentation/screens/crop_listing_screen.dart';
import 'package:kheteebaadi/features/crop_listing/presentation/screens/listing_preview_screen.dart';
import 'package:kheteebaadi/features/crop_listing/presentation/screens/my_listings_screen.dart';
import 'package:kheteebaadi/features/home/presentation/screens/home_screen.dart';
import 'package:kheteebaadi/features/mandi_prices/presentation/screens/mandi_prices_screen.dart';
import 'package:kheteebaadi/features/orders/presentation/screens/orders_screen.dart';
import 'package:kheteebaadi/features/payment/presentation/screens/payment_pending_screen.dart';
import 'package:kheteebaadi/features/payment/presentation/screens/payment_screen.dart';
import 'package:kheteebaadi/features/profile/presentation/screens/profile_screen.dart';
import 'package:kheteebaadi/features/store/presentation/screens/cart_screen.dart';
import 'package:kheteebaadi/features/store/presentation/screens/product_detail_screen.dart';
import 'package:kheteebaadi/features/store/presentation/screens/product_list_screen.dart';
import 'package:kheteebaadi/features/store/presentation/screens/store_home_screen.dart';
import 'package:kheteebaadi/features/sync/presentation/providers/sync_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Initialize Intl
  Intl.defaultLocale = 'en_IN';

  runApp(const ProviderScope(child: KheteebadiApp()));
}

class KheteebadiApp extends ConsumerStatefulWidget {
  const KheteebadiApp({Key? key}) : super(key: key);

  @override
  ConsumerState<KheteebadiApp> createState() => _KheteebadiAppState();
}

class _KheteebadiAppState extends ConsumerState<KheteebadiApp> {
  late GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      initialLocation: '/login',
      redirect: (context, state) async {
        final authState = ref.read(authProvider);

        if (state.matchedLocation == '/login' && authState.isAuthenticated) {
          return '/home';
        }

        if (state.matchedLocation != '/login' &&
            !authState.isAuthenticated) {
          return '/login';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/mandi',
          name: 'mandi',
          builder: (context, state) => const MandiPricesScreen(),
        ),
        GoRoute(
          path: '/crop-listing',
          name: 'crop-listing',
          builder: (context, state) => const CropListingScreen(),
        ),
        GoRoute(
          path: '/crop-listing/preview',
          name: 'listing-preview',
          builder: (context, state) => const ListingPreviewScreen(),
        ),
        GoRoute(
          path: '/my-listings',
          name: 'my-listings',
          builder: (context, state) => const MyListingsScreen(),
        ),
        GoRoute(
          path: '/store',
          name: 'store',
          builder: (context, state) => const StoreHomeScreen(),
        ),
        GoRoute(
          path: '/store/category/:categoryId',
          name: 'product-list',
          builder: (context, state) {
            final categoryId = state.pathParameters['categoryId'] ?? '';
            return ProductListScreen(categoryId: categoryId);
          },
        ),
        GoRoute(
          path: '/store/product/:productId',
          name: 'product-detail',
          builder: (context, state) {
            final productId = state.pathParameters['productId'] ?? '';
            return ProductDetailScreen(productId: productId);
          },
        ),
        GoRoute(
          path: '/cart',
          name: 'cart',
          builder: (context, state) => const CartScreen(),
        ),
        GoRoute(
          path: '/payment/:orderId',
          name: 'payment',
          builder: (context, state) {
            final orderId = state.pathParameters['orderId'] ?? '';
            return PaymentScreen(orderId: orderId);
          },
        ),
        GoRoute(
          path: '/payment-pending/:orderId',
          name: 'payment-pending',
          builder: (context, state) {
            final orderId = state.pathParameters['orderId'] ?? '';
            return PaymentPendingScreen(orderId: orderId);
          },
        ),
        GoRoute(
          path: '/orders',
          name: 'orders',
          builder: (context, state) => const OrdersScreen(),
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(
          title: const Text('Page Not Found'),
        ),
        body: Center(
          child: Text('Page not found: ${state.location}'),
        ),
      ),
    );

    // Initialize sync engine and register background sync
    _initializeSync();

    // Check for pending payments on app resume
    _checkPendingPayments();
  }

  void _initializeSync() {
    // Start periodic sync when connectivity changes
    final connectivityService = ref.read(connectivityServiceProvider);

    connectivityService.connectionStream.listen((isConnected) {
      if (isConnected) {
        final syncControl = ref.read(syncControlProvider);
        syncControl.performSync();
      }
    });
  }

  void _checkPendingPayments() {
    // Check for initiated payments and redirect if found
    // This would be called on app resume
    // Implementation depends on how pending payments are tracked
    // Typically from a database query or provider
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
      locale: const Locale('en', 'IN'),
      supportedLocales: AppConstants.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
    );
  }
}
