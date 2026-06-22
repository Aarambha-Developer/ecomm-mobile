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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          const SizedBox(height: 24),
          Center(
            child: GestureDetector(
              onTap: authState.status == AuthStatus.authenticated
                  ? () => context.push('/profile/edit')
                  : null,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 36),
          if (authState.status == AuthStatus.authenticated) ...[
            _buildSection(context, 'Account Settings', [
              _menuItem(context, Icons.person_outline, 'Edit Profile',
                  onTap: () => context.push('/profile/edit')),
              _menuItem(context, Icons.lock_outline, 'Change Password',
                  onTap: () => context.push('/profile/change-password')),
              _menuItem(context, Icons.location_on_outlined, 'My Addresses',
                  onTap: () => context.push('/addresses')),
            ]),
            const SizedBox(height: 16),
          ],
          _buildSection(context, 'Shopping', [
            _menuItem(context, Icons.shopping_bag_outlined, 'My Orders',
                onTap: () => context.push('/orders')),
            _menuItem(context, Icons.favorite_outline, 'My Wishlist',
                onTap: () => context.push('/wishlist')),
          ]),
          const SizedBox(height: 16),
          _buildSection(context, 'Support', [
            _menuItem(context, Icons.contact_mail_outlined, 'Contact Us',
                onTap: () => context.push('/contact')),
          ]),
          const SizedBox(height: 24),
          if (authState.status == AuthStatus.authenticated)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ref.read(authProvider.notifier).logout();
                  context.go('/');
                },
                icon: const Icon(Icons.logout, size: 20),
                label: const Text('Sign Out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/login'),
                icon: const Icon(Icons.login, size: 20),
                label: const Text('Sign In'),
              ),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textHint,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _menuItem(BuildContext context, IconData icon, String label,
      {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textPrimary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}
