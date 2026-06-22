import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primaryLight,
            child: Icon(Icons.person, size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Guest User',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 32),
          _menuItem(context, Icons.shopping_bag_outlined, 'My Orders',
              onTap: () => Navigator.of(context).pushNamed('/orders')),
          _menuItem(context, Icons.favorite_outline, 'My Wishlist',
              onTap: () => Navigator.of(context).pushNamed('/wishlist')),
          _menuItem(context, Icons.reviews_outlined, 'My Reviews',
              onTap: () {}),
          _menuItem(context, Icons.contact_mail_outlined, 'Contact Us',
              onTap: () => Navigator.of(context).pushNamed('/contact')),
          const Divider(height: 32),
          _menuItem(context, Icons.logout, 'Sign In',
              isDestructive: false,
              onTap: () => Navigator.of(context).pushNamed('/login')),
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
