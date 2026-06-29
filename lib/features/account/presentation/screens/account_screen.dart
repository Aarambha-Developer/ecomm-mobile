import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aarambha_app/core/theme/app_colors.dart';
import 'package:aarambha_app/features/auth/presentation/providers/auth_provider.dart';

class AccountScreen extends ConsumerWidget {
  final bool showAppBar;
  const AccountScreen({super.key, this.showAppBar = false});

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
      appBar: showAppBar ? AppBar(title: const Text('Account')) : null,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.glowMint, AppColors.background],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          children: [
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
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
                          radius: 42,
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
                  const SizedBox(height: 14),
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
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (authState.status == AuthStatus.authenticated) ...[
              _buildSection(context, 'Account Settings', [
                _menuItem(context, Icons.person_outline, 'Edit Profile',
                    onTap: () => context.push('/profile/edit')),
                _menuItem(context, Icons.lock_outline, 'Change Password',
                    onTap: () => context.push('/profile/change-password')),
              ]),
              const SizedBox(height: 14),
            ] else ...[
              _buildSection(context, 'Account', [
                _menuItem(context, Icons.login_outlined, 'Login',
                    onTap: () => context.push('/login')),
                _menuItem(context, Icons.person_add_outlined, 'Signup',
                    onTap: () => context.push('/register')),
              ]),
              const SizedBox(height: 14),
            ],
            _buildSection(context, 'Shopping', [
              _menuItem(context, Icons.shopping_bag_outlined, 'My Orders',
                  onTap: () => context.push('/orders')),
              _menuItem(context, Icons.favorite_outline, 'My Wishlist',
                  onTap: () => context.push('/wishlist')),
              _menuItem(context, Icons.location_on_outlined, 'Saved Addresses',
                  onTap: () => context.push('/addresses')),
            ]),
            const SizedBox(height: 14),
            _buildSection(context, 'Support', [
              _menuItem(context, Icons.contact_mail_outlined, 'Contact Us',
                  onTap: () => context.push('/contact-details')),
              _menuItem(context, Icons.report_problem_outlined, 'Report Issue',
                  onTap: () => context.push('/contact')),
            ]),
            const SizedBox(height: 14),
            _buildSection(context, 'Legal & Info', [
              _menuItem(context, Icons.local_shipping_outlined, 'Shipping & Return Policy',
                  onTap: () => context.push('/shipping-policy')),
              _menuItem(context, Icons.policy_outlined, 'Policies',
                  onTap: () => context.push('/policies')),
              _menuItem(context, Icons.description_outlined, 'Terms and Conditions',
                  onTap: () => context.push('/terms')),
              _menuItem(context, Icons.info_outline, 'About Lumora Nine',
                  onTap: () => context.push('/about')),
            ]),
            const SizedBox(height: 22),
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
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1),
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
