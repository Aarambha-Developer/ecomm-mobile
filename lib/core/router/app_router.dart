import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
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
import '../../features/auth/presentation/screens/profile_edit_screen.dart';
import '../../features/auth/presentation/screens/change_password_screen.dart';
import '../../features/addresses/presentation/screens/addresses_list_screen.dart';
import '../../features/addresses/presentation/screens/address_form_screen.dart';

class AppRouter {
  final GlobalKey<NavigatorState> _rootNavigatorKey;

  AppRouter(this._rootNavigatorKey);

  late final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
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
            address: state.extra as dynamic,
          );
        },
      ),
    ],
  );

  CustomTransitionPage _noTransitionPage(GoRouterState state, Widget child) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
    );
  }
}

class _MainShell extends StatelessWidget {
  final Widget child;

  const _MainShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    int currentIndex = 0;
    if (location == '/cart') currentIndex = 1;
    if (location == '/wishlist') currentIndex = 2;
    if (location == '/account') currentIndex = 3;

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            activeIcon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_outline),
            activeIcon: Icon(Icons.favorite),
            label: 'Wishlist',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
