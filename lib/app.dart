import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:clarity_flutter/clarity_flutter.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/storage/local_cart_provider.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/cart/presentation/providers/cart_provider.dart';
import 'features/wishlist/presentation/providers/wishlist_provider.dart';

class AarambhaApp extends ConsumerStatefulWidget {
  const AarambhaApp({super.key});

  @override
  ConsumerState<AarambhaApp> createState() => _AarambhaAppState();
}

class _AarambhaAppState extends ConsumerState<AarambhaApp> {
  late final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();
  late final GoRouter _router = AppRouter(_rootNavigatorKey, ref).router;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAnalyticsAndTracking();
    });
  }

  Future<void> _initAnalyticsAndTracking() async {
    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        await Future.delayed(const Duration(milliseconds: 1000));
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
    } catch (_) {
      // Safe guard against errors on unsupported platforms/versions
    }
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  Future<void> _syncLocalCartToServer() async {
    await ref.read(cartProvider.notifier).loadCart();

    final localItems = ref.read(localCartProvider).items;
    if (localItems.isEmpty) return;

    bool allSucceeded = true;
    final cartNotifier = ref.read(cartProvider.notifier);
    for (final item in localItems) {
      try {
        final succeeded = await cartNotifier.addItem(
          productId: item.productId,
          quantity: item.quantity,
        );
        if (!succeeded) {
          allSucceeded = false;
        }
      } catch (_) {
        allSucceeded = false;
      }
    }
    if (allSucceeded) {
      ref.read(localCartProvider.notifier).clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (prev, next) {
      if (prev?.status != AuthStatus.authenticated &&
          next.status == AuthStatus.authenticated) {
        _syncLocalCartToServer();
        ref.read(wishlistProvider.notifier).loadWishlist();
      }
    });

    return ClarityWidget(
      clarityConfig: ClarityConfig(projectId: 'xdf5l7xrrq'),
      app: MaterialApp.router(
        title: 'Lumora Nine',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
      ),
    );
  }
}
