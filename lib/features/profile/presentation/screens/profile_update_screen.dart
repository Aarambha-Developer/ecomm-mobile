import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aarambha_app/core/theme/app_colors.dart';
import 'package:aarambha_app/core/network/api_exceptions.dart';
import 'package:aarambha_app/features/auth/data/models/auth_user.dart';
import 'package:aarambha_app/features/auth/presentation/providers/auth_provider.dart';

class ProfileUpdateScreen extends ConsumerStatefulWidget {
  const ProfileUpdateScreen({super.key});

  @override
  ConsumerState<ProfileUpdateScreen> createState() => _ProfileUpdateScreenState();
}

class _ProfileUpdateScreenState extends ConsumerState<ProfileUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;
  String _avatarInitial = 'U';

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _nameCtrl.addListener(_updateAvatar);
    _fetchProfile();
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(_updateAvatar);
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _updateAvatar() {
    final initial = _nameCtrl.text.isNotEmpty
        ? _nameCtrl.text.trim()[0].toUpperCase()
        : _avatarInitial;
    if (initial != _avatarInitial) {
      setState(() => _avatarInitial = initial);
    }
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final repo = ref.read(authRepositoryProvider);
      final profile = await repo.getProfile();
      if (!mounted) return;
      ref.read(authProvider.notifier).updateUser(profile);
      _populateFields(profile);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _populateFields(AuthUser profile) {
    _nameCtrl.text = profile.fullName ?? '';
    _emailCtrl.text = profile.email;
    _phoneCtrl.text = profile.phoneNumber ?? '';
    final initial = _nameCtrl.text.isNotEmpty
        ? _nameCtrl.text.trim()[0].toUpperCase()
        : (profile.email.isNotEmpty
            ? profile.email[0].toUpperCase()
            : 'U');
    _avatarInitial = initial;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(authRepositoryProvider);
      final phoneText = _phoneCtrl.text.trim();
      final updated = await repo.updateProfile(
        fullName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phoneNumber: phoneText.isNotEmpty ? phoneText : null,
        clearPhoneNumber: phoneText.isEmpty,
      );

      ref.read(authProvider.notifier).updateUser(updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } on ProfileUpdateException catch (e) {
      if (!mounted) return;

      final fieldSummary = e.fieldErrorsSummary;
      final message = fieldSummary ?? e.message;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text(
                'Loading profile...',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (_loadError != null && user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(_loadError!, style: const TextStyle(color: AppColors.error)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchProfile,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Center(
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        _avatarInitial,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'Enter your full name',
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      final trimmed = v?.trim();
                      if (trimmed == null || trimmed.isEmpty) {
                        return 'Full name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'Email is read-only',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    readOnly: true,
                    enabled: false,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      hintText: 'Enter your phone number',
                    ),
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      child: const Text('Save Changes'),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          if (_isSaving)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
