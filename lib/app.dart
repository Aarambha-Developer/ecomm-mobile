import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/storage/local_cart_provider.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/cart/presentation/providers/cart_provider.dart';

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
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  Future<void> _syncLocalCartToServer() async {
    final localItems = ref.read(localCartProvider).items;
    if (localItems.isEmpty) return;

    bool allSucceeded = true;
    final cartNotifier = ref.read(cartProvider.notifier);
    for (final item in localItems) {
      try {
        await cartNotifier.addItem(
          productId: item.productId,
          quantity: item.quantity,
        );
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
      }
    });

    return MaterialApp.router(
      title: 'Lumora Nine',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
