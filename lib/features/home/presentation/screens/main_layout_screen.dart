import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aarambha_app/core/theme/app_colors.dart';
import 'package:aarambha_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:aarambha_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:aarambha_app/features/home/presentation/screens/home_screen.dart';
import 'package:aarambha_app/features/products/presentation/screens/explore_screen.dart';
import 'package:aarambha_app/features/categories/presentation/screens/categories_screen.dart';
import 'package:aarambha_app/features/home/presentation/screens/offers_screen.dart';
import 'package:aarambha_app/features/account/presentation/screens/account_screen.dart';
import 'package:aarambha_app/features/wishlist/presentation/providers/wishlist_provider.dart';

final mainLayoutIndexProvider = StateProvider<int>((ref) => 0);

class MainLayoutScreen extends ConsumerWidget {
  const MainLayoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(mainLayoutIndexProvider);
    final cartState = ref.watch(cartProvider);
    final cartItemsCount = cartState.valueOrNull?.totalItems ?? 0;
    final wishlistState = ref.watch(wishlistProvider);
    final wishlistItemsCount = wishlistState.valueOrNull?.productCount ?? 0;
    final authState = ref.watch(authProvider);
    final user = authState.user;

    final screens = const [
      HomeScreen(),
      ExploreScreen(),
      CategoriesScreen(),
      OffersScreen(),
      AccountScreen(),
    ];

    final titles = const [
      'Lumora Nine',
      'Explore Products',
      'Categories',
      'Special Offers',
      'Account',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          titles[currentIndex],
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.push('/search'),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.favorite_border_rounded),
                onPressed: () => context.push('/wishlist'),
              ),
              if (wishlistItemsCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Badge(
                    label: Text(
                      '$wishlistItemsCount',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: AppColors.primary,
                  ),
                ),
            ],
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () => context.push('/cart'),
              ),
              if (cartItemsCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Badge(
                    label: Text(
                      '$cartItemsCount',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: AppColors.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  user != null
                      ? (user.fullName?.isNotEmpty == true
                              ? user.fullName![0]
                              : user.email[0])
                          .toUpperCase()
                      : 'G',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              accountName: Text(
                user?.fullName ?? 'Welcome Guest',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              accountEmail: Text(
                user?.email ?? 'Sign in to sync your profile',
                style: const TextStyle(fontSize: 13),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
                ref.read(mainLayoutIndexProvider.notifier).state = 0;
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_bag_outlined),
              title: const Text('My Orders'),
              onTap: () {
                Navigator.pop(context);
                context.push('/orders');
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite_outline),
              title: const Text('Wishlist'),
              onTap: () {
                Navigator.pop(context);
                context.push('/wishlist');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings feature coming soon!')),
                );
              },
            ),
            const Spacer(),
            const Divider(),
            if (authState.status == AuthStatus.authenticated)
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/');
                    ref.read(mainLayoutIndexProvider.notifier).state = 0;
                  }
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.login, color: AppColors.primary),
                title: const Text(
                  'Sign In',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/login');
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        onTap: (index) {
          ref.read(mainLayoutIndexProvider.notifier).state = index;
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category_outlined),
            activeIcon: Icon(Icons.category),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer_outlined),
            activeIcon: Icon(Icons.local_offer),
            label: 'Offers',
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
