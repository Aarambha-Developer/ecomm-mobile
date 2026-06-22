import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aarambha_app/core/theme/app_colors.dart';
import 'package:aarambha_app/features/auth/presentation/providers/auth_provider.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final displayName = user?.fullName ?? user?.email ?? 'Guest User';
    final initial = user != null
        ? (user.fullName?.isNotEmpty == true
                ? user.fullName![0]
                : user.email[0])
            .toUpperCase()
        : 'G';

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 20),
          GestureDetector(
            onTap: authState.status == AuthStatus.authenticated
                ? () => context.push('/profile/edit')
                : null,
            child: CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primaryLight,
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            displayName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (user?.phoneNumber != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                user!.phoneNumber!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          const SizedBox(height: 32),
          if (authState.status == AuthStatus.authenticated) ...[
            _menuItem(
              context,
              Icons.person_outline,
              'Edit Profile',
              onTap: () => context.push('/profile/edit'),
            ),
            _menuItem(
              context,
              Icons.lock_outline,
              'Change Password',
              onTap: () => context.push('/profile/change-password'),
            ),
            _menuItem(
              context,
              Icons.location_on_outlined,
              'My Addresses',
              onTap: () => context.push('/addresses'),
            ),
          ],
          _menuItem(
            context,
            Icons.shopping_bag_outlined,
            'My Orders',
            onTap: () => context.push('/orders'),
          ),
          _menuItem(
            context,
            Icons.favorite_outline,
            'My Wishlist',
            onTap: () => context.push('/wishlist'),
          ),
          _menuItem(
            context,
            Icons.contact_mail_outlined,
            'Contact Us',
            onTap: () => context.push('/contact'),
          ),
          const Divider(height: 32),
          if (authState.status == AuthStatus.authenticated)
            _menuItem(
              context,
              Icons.logout,
              'Sign Out',
              isDestructive: true,
              onTap: () {
                ref.read(authProvider.notifier).logout();
                context.go('/');
              },
            )
          else
            _menuItem(
              context,
              Icons.login,
              'Sign In',
              onTap: () => context.push('/login'),
            ),
        ],
      ),
    );
  }

  Widget _menuItem(BuildContext context, IconData icon, String label,
      {bool isDestructive = false, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? AppColors.error : AppColors.textPrimary,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isDestructive ? AppColors.error : AppColors.textPrimary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
