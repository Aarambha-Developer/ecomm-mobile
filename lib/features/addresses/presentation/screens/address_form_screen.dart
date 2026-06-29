import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aarambha_app/core/theme/app_colors.dart';
import 'package:aarambha_app/features/addresses/presentation/providers/addresses_provider.dart';
import 'package:aarambha_app/features/addresses/data/models/address.dart';
import 'package:aarambha_app/features/checkout/presentation/providers/payment_selection_provider.dart';
import 'package:aarambha_app/features/checkout/data/models/delivery_area.dart';

class AddressFormScreen extends ConsumerStatefulWidget {
  final Address? address;

  const AddressFormScreen({super.key, this.address});

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _labelCtrl;
  late TextEditingController _fullNameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _provinceCtrl;
  late TextEditingController _districtCtrl;
  late TextEditingController _municipalityCtrl;
  late TextEditingController _streetCtrl;
  late TextEditingController _zipCtrl;
  bool _isDefault = false;
  bool _isSaving = false;

  List<DeliveryArea> _allDeliveryAreas = [];
  String? _selectedProvince;
  String? _selectedDistrict;
  String? _selectedMunicipality;

  bool get _isEditing => widget.address != null;

  List<String> get _provinces {
    return _allDeliveryAreas.map((e) => e.province).toSet().toList()..sort();
  }

  List<String> get _districts {
    if (_selectedProvince == null) return [];
    return _allDeliveryAreas
        .where((e) => e.province == _selectedProvince)
        .map((e) => e.district)
        .toSet()
        .toList()
      ..sort();
  }

  List<String> get _municipalities {
    if (_selectedProvince == null || _selectedDistrict == null) return [];
    return _allDeliveryAreas
        .where((e) =>
            e.province == _selectedProvince && e.district == _selectedDistrict)
        .map((e) => e.municipality)
        .toSet()
        .toList()
      ..sort();
  }

  @override
  void initState() {
    super.initState();
    final a = widget.address;
    _labelCtrl = TextEditingController(text: a?.label ?? '');
    _fullNameCtrl = TextEditingController(text: a?.fullName ?? '');
    _phoneCtrl = TextEditingController(text: a?.phone ?? '');
    _provinceCtrl = TextEditingController(text: a?.province ?? '');
    _districtCtrl = TextEditingController(text: a?.district ?? '');
    _municipalityCtrl = TextEditingController(text: a?.municipality ?? '');
    _streetCtrl = TextEditingController(text: a?.street ?? '');
    _zipCtrl = TextEditingController(text: a?.zipCode ?? '');
    _isDefault = a?.isDefault ?? false;

    _selectedProvince = a?.province != null && a!.province.isNotEmpty ? a.province : null;
    _selectedDistrict = a?.district != null && a!.district.isNotEmpty ? a.district : null;
    _selectedMunicipality = a?.municipality != null && a!.municipality.isNotEmpty ? a.municipality : null;
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _provinceCtrl.dispose();
    _districtCtrl.dispose();
    _municipalityCtrl.dispose();
    _streetCtrl.dispose();
    _zipCtrl.dispose();
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
        fullName: _fullNameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        province: _provinceCtrl.text.trim(),
        district: _districtCtrl.text.trim(),
        municipality: _municipalityCtrl.text.trim(),
        street: _streetCtrl.text.trim(),
        zipCode: _zipCtrl.text.trim().isEmpty ? null : _zipCtrl.text.trim(),
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
    final deliveryAreasAsync = ref.watch(deliveryAreasProvider);
    deliveryAreasAsync.whenData((areas) {
      if (_allDeliveryAreas.isEmpty && areas.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _allDeliveryAreas = areas;
            if (_selectedProvince != null) {
              final matchedProvince = _provinces
                  .where((e) => e.toLowerCase() == _selectedProvince!.toLowerCase())
                  .firstOrNull;
              if (matchedProvince != null) {
                _selectedProvince = matchedProvince;
                if (_selectedDistrict != null) {
                  final matchedDistrict = _districts
                      .where((e) => e.toLowerCase() == _selectedDistrict!.toLowerCase())
                      .firstOrNull;
                  if (matchedDistrict != null) {
                    _selectedDistrict = matchedDistrict;
                    if (_selectedMunicipality != null) {
                      final matchedMunicipality = _municipalities
                          .where((e) => e.toLowerCase() == _selectedMunicipality!.toLowerCase())
                          .firstOrNull;
                      if (matchedMunicipality != null) {
                        _selectedMunicipality = matchedMunicipality;
                      }
                    }
                  }
                }
              }
            }
          });
        });
      }
    });

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
                controller: _fullNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Recipient Full Name *',
                  hintText: 'e.g. John Doe',
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  hintText: 'Contact number for delivery',
                ),
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              const Text('Province *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              if (_allDeliveryAreas.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _selectedProvince,
                      hint: const Text('Select Province'),
                      items: _provinces.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                      validator: (v) => v == null ? 'Required' : null,
                      onChanged: (value) {
                        setState(() {
                          _selectedProvince = value;
                          _selectedDistrict = null;
                          _selectedMunicipality = null;
                          _provinceCtrl.text = value ?? '';
                          _districtCtrl.clear();
                          _municipalityCtrl.clear();
                        });
                      },
                    ),
                  ),
                )
              else
                TextFormField(
                  controller: _provinceCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Province *',
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),

              const SizedBox(height: 16),
              const Text('District *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              if (_allDeliveryAreas.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _selectedDistrict,
                      hint: const Text('Select District'),
                      items: _districts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                      validator: (v) => v == null ? 'Required' : null,
                      onChanged: _selectedProvince == null
                          ? null
                          : (value) {
                              setState(() {
                                _selectedDistrict = value;
                                _selectedMunicipality = null;
                                _districtCtrl.text = value ?? '';
                                _municipalityCtrl.clear();
                              });
                            },
                    ),
                  ),
                )
              else
                TextFormField(
                  controller: _districtCtrl,
                  decoration: const InputDecoration(
                    labelText: 'District *',
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),

              const SizedBox(height: 16),
              const Text('Municipality *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              if (_allDeliveryAreas.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _selectedMunicipality,
                      hint: const Text('Select Municipality'),
                      items: _municipalities.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                      validator: (v) => v == null ? 'Required' : null,
                      onChanged: _selectedDistrict == null
                          ? null
                          : (value) {
                              setState(() {
                                _selectedMunicipality = value;
                                _municipalityCtrl.text = value ?? '';
                              });
                            },
                    ),
                  ),
                )
              else
                TextFormField(
                  controller: _municipalityCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Municipality *',
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _zipCtrl,
                decoration: const InputDecoration(
                  labelText: 'ZIP Code (optional)',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _streetCtrl,
                decoration: const InputDecoration(
                  labelText: 'Street Address *',
                  hintText: 'e.g. Street name, Area, Building',
                ),
                maxLines: 2,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
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
