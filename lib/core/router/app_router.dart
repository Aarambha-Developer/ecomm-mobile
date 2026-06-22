import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/profile_edit_screen.dart';
import '../../features/auth/presentation/screens/change_password_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/cart/presentation/screens/cart_screen.dart';
import '../../features/wishlist/presentation/screens/wishlist_screen.dart';
import '../../features/account/presentation/screens/account_screen.dart';
import '../../features/products/presentation/screens/product_list_screen.dart';
import '../../features/products/presentation/screens/product_detail_screen.dart';
import '../../features/categories/presentation/screens/category_products_screen.dart';
import '../../features/brands/presentation/screens/brand_products_screen.dart';
import '../../features/orders/presentation/screens/orders_list_screen.dart';
import '../../features/orders/presentation/screens/order_detail_screen.dart';
import '../../features/checkout/presentation/screens/checkout_screen.dart';
import '../../features/contact/presentation/screens/contact_screen.dart';
import '../../features/addresses/presentation/screens/addresses_list_screen.dart';
import '../../features/addresses/presentation/screens/address_form_screen.dart';
import '../../features/addresses/data/models/address.dart';

class AppRouter {
  final GlobalKey<NavigatorState> _rootNavigatorKey;
  final WidgetRef _ref;

  AppRouter(this._rootNavigatorKey, this._ref);

  static const _protectedRoutes = <String>{
    '/orders',
    '/checkout',
    '/addresses',
    '/addresses/add',
    '/addresses/edit',
    '/profile/edit',
    '/profile/change-password',
  };

  static const _authRoutes = <String>{
    '/login',
    '/register',
    '/forgot-password',
  };

  late final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final authState = _ref.read(authProvider);
      final isLoggedIn = authState.status == AuthStatus.authenticated;
      final isInitial = authState.status == AuthStatus.initial ||
          authState.status == AuthStatus.loading;
      final path = state.uri.path;

      if (isInitial) return null;

      final isProtected = _protectedRoutes.any(path.startsWith) ||
          path == '/cart' ||
          path == '/wishlist';

      if (isProtected && !isLoggedIn) {
        return '/login';
      }

      if (_authRoutes.contains(path) && isLoggedIn) {
        return '/';
      }

      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) => _MainShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => _noTransitionPage(
              state,
              const HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/cart',
            pageBuilder: (context, state) => _noTransitionPage(
              state,
              const CartScreen(),
            ),
          ),
          GoRoute(
            path: '/wishlist',
            pageBuilder: (context, state) => _noTransitionPage(
              state,
              const WishlistScreen(),
            ),
          ),
          GoRoute(
            path: '/account',
            pageBuilder: (context, state) => _noTransitionPage(
              state,
              const AccountScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/products',
        builder: (context, state) => const ProductListScreen(),
      ),
      GoRoute(
        path: '/products/:slug',
        builder: (context, state) => ProductDetailScreen(
          slug: state.pathParameters['slug']!,
        ),
      ),
      GoRoute(
        path: '/categories/:slug',
        builder: (context, state) => CategoryProductsScreen(
          slug: state.pathParameters['slug']!,
        ),
      ),
      GoRoute(
        path: '/brands/:slug',
        builder: (context, state) => BrandProductsScreen(
          slug: state.pathParameters['slug']!,
        ),
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrdersListScreen(),
      ),
      GoRoute(
        path: '/orders/:id',
        builder: (context, state) => OrderDetailScreen(
          id: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/contact',
        builder: (context, state) => const ContactScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const ProfileEditScreen(),
      ),
      GoRoute(
        path: '/profile/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/addresses',
        builder: (context, state) => const AddressesListScreen(),
      ),
      GoRoute(
        path: '/addresses/add',
        builder: (context, state) => const AddressFormScreen(),
      ),
      GoRoute(
        path: '/addresses/edit',
        builder: (context, state) {
          return AddressFormScreen(
            address: state.extra as Address?,
          );
        },
      ),
    ],
  );

  CustomTransitionPage<void> _noTransitionPage(GoRouterState state, Widget child) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
    );
  }
}

class _MainShell extends ConsumerStatefulWidget {
  final Widget child;

  const _MainShell({required this.child});

  @override
  ConsumerState<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<_MainShell> {
  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    int currentIndex = 0;
    if (location == '/cart') currentIndex = 1;
    if (location == '/wishlist') currentIndex = 2;
    if (location == '/account') currentIndex = 3;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey,
          onTap: (index) {
            switch (index) {
              case 0:
                context.go('/');
                break;
              case 1:
                context.go('/cart');
                break;
              case 2:
                context.go('/wishlist');
                break;
              case 3:
                context.go('/account');
                break;
            }
          },
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, color: currentIndex == 0 ? null : Colors.grey),
              activeIcon: const Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_outlined, color: currentIndex == 1 ? null : Colors.grey),
              activeIcon: const Icon(Icons.shopping_cart),
              label: 'Cart',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline, color: currentIndex == 2 ? null : Colors.grey),
              activeIcon: const Icon(Icons.favorite),
              label: 'Wishlist',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, color: currentIndex == 3 ? null : Colors.grey),
              activeIcon: const Icon(Icons.person),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}
