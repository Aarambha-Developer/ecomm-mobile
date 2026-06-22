import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aarambha_app/core/theme/app_colors.dart';
import 'package:aarambha_app/features/addresses/presentation/providers/addresses_provider.dart';
import 'package:aarambha_app/features/addresses/data/models/address.dart';

class AddressFormScreen extends ConsumerStatefulWidget {
  final Address? address;

  const AddressFormScreen({super.key, this.address});

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _labelCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _stateCtrl;
  late TextEditingController _zipCtrl;
  late TextEditingController _countryCtrl;
  late TextEditingController _phoneCtrl;
  bool _isDefault = false;
  bool _isSaving = false;

  bool get _isEditing => widget.address != null;

  @override
  void initState() {
    super.initState();
    final a = widget.address;
    _labelCtrl = TextEditingController(text: a?.label ?? '');
    _addressCtrl = TextEditingController(text: a?.fullAddress ?? '');
    _cityCtrl = TextEditingController(text: a?.city ?? '');
    _stateCtrl = TextEditingController(text: a?.state ?? '');
    _zipCtrl = TextEditingController(text: a?.zipCode ?? '');
    _countryCtrl = TextEditingController(text: a?.country ?? '');
    _phoneCtrl = TextEditingController(text: a?.phoneNumber ?? '');
    _isDefault = a?.isDefault ?? false;
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _zipCtrl.dispose();
    _countryCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(addressesRepositoryProvider);
      final address = Address(
        id: widget.address?.id ?? '',
        label: _labelCtrl.text.trim(),
        fullAddress: _addressCtrl.text.trim(),
        city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
        state: _stateCtrl.text.trim().isEmpty ? null : _stateCtrl.text.trim(),
        zipCode: _zipCtrl.text.trim().isEmpty ? null : _zipCtrl.text.trim(),
        country:
            _countryCtrl.text.trim().isEmpty ? null : _countryCtrl.text.trim(),
        phoneNumber:
            _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        isDefault: _isDefault,
      );

      if (_isEditing) {
        await repo.updateAddress(widget.address!.id, address);
      } else {
        await repo.createAddress(address);
      }

      ref.invalidate(addressesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Address updated' : 'Address added'),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Address' : 'Add Address'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _labelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Label',
                  hintText: 'e.g. Home, Office',
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Full Address',
                  hintText: 'Street, building, area...',
                ),
                maxLines: 3,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityCtrl,
                      decoration: const InputDecoration(
                        labelText: 'City',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _stateCtrl,
                      decoration: const InputDecoration(
                        labelText: 'State',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _zipCtrl,
                      decoration: const InputDecoration(
                        labelText: 'ZIP Code',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _countryCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Country',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Contact number for this address',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Set as default address'),
                value: _isDefault,
                onChanged: (v) =>
                    setState(() => _isDefault = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : Text(_isEditing ? 'Update Address' : 'Add Address'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
