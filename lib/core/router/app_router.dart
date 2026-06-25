import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/profile_edit_screen.dart';
import '../../features/auth/presentation/screens/change_password_screen.dart';
import '../../features/home/presentation/screens/main_layout_screen.dart';
import '../../features/cart/presentation/screens/cart_screen.dart';
import '../../features/wishlist/presentation/screens/wishlist_screen.dart';
import '../../features/account/presentation/screens/account_screen.dart';
import '../../features/products/presentation/screens/product_list_screen.dart';
import '../../features/products/presentation/screens/product_detail_screen.dart';
import '../../features/products/presentation/screens/search_screen.dart';
import '../../features/categories/presentation/screens/category_products_screen.dart';
import '../../features/brands/presentation/screens/brand_products_screen.dart';
import '../../features/orders/presentation/screens/orders_list_screen.dart';
import '../../features/orders/presentation/screens/order_detail_screen.dart';
import '../../features/checkout/presentation/screens/payment_selection_screen.dart';
import '../../features/contact/presentation/screens/contact_screen.dart';
import '../../features/contact/presentation/screens/contact_details_screen.dart';
import '../../features/home/data/models/home_models.dart';
import '../../features/home/presentation/screens/story_viewer_screen.dart';
// TODO: Re-enable when API endpoints are available
// import '../../features/addresses/presentation/screens/addresses_list_screen.dart';
// import '../../features/addresses/presentation/screens/address_form_screen.dart';
// import '../../features/addresses/data/models/address.dart';

class AppRouter {
  final GlobalKey<NavigatorState> _rootNavigatorKey;
  final WidgetRef _ref;

  AppRouter(this._rootNavigatorKey, this._ref);

  static const _protectedRoutes = <String>{
    '/orders',
    '/checkout',
    // '/addresses',
    // '/addresses/add',
    // '/addresses/edit',
    '/profile/edit',
    // '/profile/change-password',
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

      final isProtected = _protectedRoutes.any(path.startsWith);

      if (isProtected && !isLoggedIn) {
        final redirect = Uri.encodeComponent(state.uri.toString());
        return '/login?redirect=$redirect';
      }

      if (_authRoutes.contains(path) && isLoggedIn) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const MainLayoutScreen(),
      ),
      GoRoute(
        path: '/stories',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          final stories = extra['stories'] as List<Offer>;
          final initialIndex = extra['initialIndex'] as int;
          return StoryViewerScreen(
            stories: stories,
            initialIndex: initialIndex,
          );
        },
      ),
      GoRoute(
        path: '/cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/wishlist',
        builder: (context, state) => const WishlistScreen(),
      ),
      GoRoute(
        path: '/account',
        builder: (context, state) => const AccountScreen(),
      ),
      GoRoute(
        path: '/products',
        builder: (context, state) => const ProductListScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
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
        builder: (context, state) => const PaymentSelectionScreen(),
      ),
      GoRoute(
        path: '/contact',
        builder: (context, state) => const ContactScreen(),
      ),
      GoRoute(
        path: '/contact-details',
        builder: (context, state) => const ContactDetailsScreen(),
      ),
      GoRoute(
        path: '/policies',
        builder: (context, state) => const StaticContentViewerScreen(
          title: 'Policies',
          content: 'Privacy & Refund Policy\n\n1. Privacy Policy\nAt Lumora Nine, we value your privacy. We collect your personal information such as name, email, and phone number only to provide our services and process your orders. We do not sell your personal data to third parties.\n\n2. Refund Policy\nIf you are not satisfied with your purchase, you may return the unused product within 15 days of delivery for a full refund or exchange. Shipping costs are non-refundable.',
        ),
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const StaticContentViewerScreen(
          title: 'Terms & Conditions',
          content: 'Terms and Conditions\n\nWelcome to Lumora Nine. By using our application, you agree to comply with and be bound by the following terms and conditions:\n\n1. Account Security\nYou are responsible for maintaining the confidentiality of your account credentials.\n\n2. Product Information\nWe strive to display product colors and details as accurately as possible. However, we cannot guarantee your screen\'s display will be completely accurate.\n\n3. Limitation of Liability\nLumora Nine shall not be liable for any direct, indirect, incidental, or consequential damages arising from your use of our services.',
        ),
      ),
      GoRoute(
        path: '/about',
        builder: (context, state) => const StaticContentViewerScreen(
          title: 'About Lumora Nine',
          content: 'About Lumora Nine\n\nLumora Nine is a premium cosmetics and skincare brand dedicated to bringing you the highest quality beauty products. Founded on the principles of purity, efficacy, and inclusivity, we craft our products using ethically sourced ingredients.\n\nOur mission is to empower everyone to express their unique beauty. Thank you for choosing Lumora Nine as your beauty partner.',
        ),
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
      // TODO: /addresses routes disabled - /addresses/ endpoint does not exist in API spec
      // GoRoute(
      //   path: '/addresses',
      //   builder: (context, state) => const AddressesListScreen(),
      // ),
      // GoRoute(
      //   path: '/addresses/add',
      //   builder: (context, state) => const AddressFormScreen(),
      // ),
      // GoRoute(
      //   path: '/addresses/edit',
      //   builder: (context, state) {
      //     return AddressFormScreen(
      //       address: state.extra as Address?,
      //     );
      //   },
      // ),
    ],
  );


}


