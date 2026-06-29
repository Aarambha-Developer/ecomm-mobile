import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:gal/gal.dart';

import 'package:aarambha_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:aarambha_app/core/theme/app_colors.dart';
import 'package:aarambha_app/core/utils/formatters.dart';
import 'package:aarambha_app/core/utils/toast_utils.dart';
import 'package:aarambha_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:aarambha_app/features/checkout/data/models/order_request.dart';
import 'package:aarambha_app/features/checkout/data/models/payment_method.dart';
import 'package:aarambha_app/features/addresses/presentation/providers/addresses_provider.dart';
import 'package:aarambha_app/features/addresses/data/models/address.dart';
import 'package:aarambha_app/features/checkout/data/models/delivery_area.dart';
import 'package:aarambha_app/features/checkout/presentation/providers/payment_selection_provider.dart';
import 'package:aarambha_app/features/checkout/presentation/screens/order_success_screen.dart';

class PaymentSelectionScreen extends ConsumerStatefulWidget {
  const PaymentSelectionScreen({super.key});

  @override
  ConsumerState<PaymentSelectionScreen> createState() =>
      _PaymentSelectionScreenState();
}

class _PaymentSelectionScreenState
    extends ConsumerState<PaymentSelectionScreen> {
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _provinceController = TextEditingController();
  final _districtController = TextEditingController();
  final _municipalityController = TextEditingController();
  final _streetController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _notesController = TextEditingController();
  String? _appliedCouponCode;

  List<DeliveryArea> _allDeliveryAreas = [];
  DeliveryArea? _matchedArea;
  Address? _selectedSavedAddress;
  String? _selectedProvince;
  String? _selectedDistrict;
  String? _selectedMunicipality;
  bool _useSavedAddress = true;
  bool _saveAddressChecked = true;
  bool _setAsDefaultChecked = true;
  final _newAddressLabelController = TextEditingController(text: 'Home');

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

  void _recalculateDeliveryCharge() {
    if (_allDeliveryAreas.isEmpty) return;

    final province = _provinceController.text.trim().toLowerCase();
    final district = _districtController.text.trim().toLowerCase();
    final municipality = _municipalityController.text.trim().toLowerCase();

    DeliveryArea? match;
    for (final area in _allDeliveryAreas) {
      if (area.province.toLowerCase() == province &&
          area.district.toLowerCase() == district &&
          area.municipality.toLowerCase() == municipality) {
        match = area;
        break;
      }
    }

    if (match == null) {
      for (final area in _allDeliveryAreas) {
        if (area.district.toLowerCase() == district &&
            area.municipality.toLowerCase() == municipality) {
          match = area;
          break;
        }
      }
    }

    if (match == null) {
      for (final area in _allDeliveryAreas) {
        if (area.municipality.toLowerCase() == municipality) {
          match = area;
          break;
        }
      }
    }

    setState(() {
      _matchedArea = match;
    });
  }

  void _applySavedAddress(Address address) {
    _fullNameController.text = address.fullName;
    _phoneController.text = address.phone;
    _provinceController.text = address.province;
    _districtController.text = address.district;
    _municipalityController.text = address.municipality;
    _streetController.text = address.street;
    _zipCodeController.text = address.zipCode ?? '';

    final matchedProvince = _provinces
        .where((p) => p.toLowerCase() == address.province.toLowerCase())
        .firstOrNull;
    if (matchedProvince != null) {
      _selectedProvince = matchedProvince;
      final matchedDistrict = _districts
          .where((d) => d.toLowerCase() == address.district.toLowerCase())
          .firstOrNull;
      if (matchedDistrict != null) {
        _selectedDistrict = matchedDistrict;
        final matchedMunicipality = _municipalities
            .where((m) => m.toLowerCase() == address.municipality.toLowerCase())
            .firstOrNull;
        if (matchedMunicipality != null) {
          _selectedMunicipality = matchedMunicipality;
        } else {
          _selectedMunicipality = null;
        }
      } else {
        _selectedDistrict = null;
        _selectedMunicipality = null;
      }
    } else {
      _selectedProvince = null;
      _selectedDistrict = null;
      _selectedMunicipality = null;
    }

    _recalculateDeliveryCharge();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prepopulateUserData();
    });
  }

  void _prepopulateUserData() {
    final user = ref.read(authProvider).user;
    if (user != null) {
      if (user.fullName != null && user.fullName!.isNotEmpty) {
        _fullNameController.text = user.fullName!;
      }
      if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
        _phoneController.text = user.phoneNumber!;
      }
      if (user.email.isNotEmpty) {
        _emailController.text = user.email;
      }
    }
  }

  bool _validateFields() {
    if (_fullNameController.text.trim().isEmpty) return false;
    if (_phoneController.text.trim().isEmpty) return false;
    if (_emailController.text.trim().isEmpty) return false;
    if (_provinceController.text.trim().isEmpty) return false;
    if (_districtController.text.trim().isEmpty) return false;
    if (_municipalityController.text.trim().isEmpty) return false;
    if (_streetController.text.trim().isEmpty) return false;
    return true;
  }

  String _resolveImageUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    const baseDomain = 'https://ecom.aitrc.com.np';
    if (path.startsWith('/')) {
      return '$baseDomain$path';
    }
    return '$baseDomain/$path';
  }

  Future<void> _downloadQrCode(String imageUrl) async {
    try {
      if (!mounted) return;
      AppToast.showInfo(context, "Downloading QR Code...");

      final response = await Dio().get<List<int>>(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data;
      if (bytes == null) throw Exception("Failed to download image bytes");

      await Gal.putImageBytes(Uint8List.fromList(bytes));

      if (mounted) {
        AppToast.showSuccess(context, "QR Code saved to gallery!");
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, "Failed to save QR Code: ${e.toString()}");
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _provinceController.dispose();
    _districtController.dispose();
    _municipalityController.dispose();
    _streetController.dispose();
    _zipCodeController.dispose();
    _notesController.dispose();
    _newAddressLabelController.dispose();
    super.dispose();
  }

  Future<void> _pickScreenshot() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 70,
    );
    if (picked != null) {
      ref
          .read(paymentSelectionProvider.notifier)
          .setScreenshotPath(picked.path);
    }
  }

  Future<void> _completeCheckout() async {
    final fullName = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final province = _provinceController.text.trim();
    final district = _districtController.text.trim();
    final municipality = _municipalityController.text.trim();
    final street = _streetController.text.trim();
    final zipCode = _zipCodeController.text.trim();

    if (fullName.isEmpty ||
        phone.isEmpty ||
        email.isEmpty ||
        province.isEmpty ||
        district.isEmpty ||
        municipality.isEmpty ||
        street.isEmpty) {
      AppToast.showError(context, 'Please fill in all required shipping fields');
      return;
    }

    final authState = ref.read(authProvider);
    if (!_useSavedAddress && _saveAddressChecked && authState.status == AuthStatus.authenticated) {
      try {
        final addressesRepo = ref.read(addressesRepositoryProvider);
        final label = _newAddressLabelController.text.trim().isNotEmpty
            ? _newAddressLabelController.text.trim()
            : 'Home';
        await addressesRepo.createAddress(Address(
          id: '',
          fullName: fullName,
          phone: phone,
          province: province,
          district: district,
          municipality: municipality,
          street: street,
          zipCode: zipCode.isNotEmpty ? zipCode : null,
          label: label,
          isDefault: _setAsDefaultChecked,
        ));
        ref.invalidate(addressesProvider);
      } catch (e) {
        debugPrint('Failed to save address: $e');
      }
    }

    final notifier = ref.read(paymentSelectionProvider.notifier);
    final orderId = await notifier.completeCheckout(
      orderRequest: OrderRequest(
        shippingFullName: fullName,
        shippingPhone: phone,
        shippingEmail: email,
        shippingProvince: province,
        shippingDistrict: district,
        shippingMunicipality: municipality,
        shippingStreet: street,
        shippingZipCode: zipCode,
        notes: _notesController.text.trim(),
      ),
      couponCode: _appliedCouponCode,
    );

    if (!mounted) return;

    if (orderId != null) {
      unawaited(ref.read(cartProvider.notifier).loadCart());
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(orderId: orderId),
        ),
      );
      return;
    }

    final message = ref.read(paymentSelectionProvider).errorMessage;
    if (message != null && message.isNotEmpty) {
      AppToast.showError(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentSelectionProvider);
    final selected = state.selectedMethod;
    final cart = ref.watch(cartProvider).valueOrNull;

    final extra = GoRouterState.of(context).extra;
    if (extra is Map<String, String?> && _appliedCouponCode == null) {
      final couponCode = extra['couponCode'];
      final couponRateStr = extra['couponRate'];
      if (couponCode != null && couponCode.isNotEmpty) {
        _appliedCouponCode = couponCode;
        if (couponRateStr != null) {
          final rate = double.tryParse(couponRateStr);
          if (rate != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                ref
                    .read(paymentSelectionProvider.notifier)
                    .applyCouponLocally(rate);
              }
            });
          }
        }
      }
    }
    final subtotal = cart?.totalAmount ?? 0;
    final discountRate = state.couponDiscountRate;
    final discount = discountRate != null ? subtotal * (discountRate / 100) : 0.0;

    final deliveryAreasAsync = ref.watch(deliveryAreasProvider);
    final addressesAsync = ref.watch(addressesProvider);

    deliveryAreasAsync.whenData((areas) {
      if (_allDeliveryAreas.isEmpty && areas.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _allDeliveryAreas = areas;
            _recalculateDeliveryCharge();
          });
        });
      }
    });

    addressesAsync.whenData((addresses) {
      if (_useSavedAddress && _selectedSavedAddress == null && addresses.isNotEmpty) {
        final defaultAddress = addresses.firstWhere((e) => e.isDefault, orElse: () => addresses.first);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _selectedSavedAddress = defaultAddress;
            _applySavedAddress(defaultAddress);
          });
        });
      } else if (addresses.isEmpty && _useSavedAddress) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _useSavedAddress = false;
          });
        });
      }
    });

    final deliveryCharge = _matchedArea?.deliveryCharge ?? 0.0;
    final total = subtotal - discount + deliveryCharge;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/cart'),
        ),
        title: const Text('Checkout'),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () =>
                ref.read(paymentSelectionProvider.notifier).loadMethods(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (cart != null && cart.items.isNotEmpty) ...[
                  _SectionCard(
                    title: 'Order Summary',
                    child: Column(
                      children: [
                        ...cart.items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.productName,
                                    style: const TextStyle(fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  'x${item.quantity}  ${Formatters.formatCurrency(item.subtotal)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal'),
                            Text(Formatters.formatCurrencyPlain(subtotal)),
                          ],
                        ),
                        if (discount > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Discount (${discountRate!.round()}%)',
                                style:
                                    const TextStyle(color: AppColors.success),
                              ),
                              Text(
                                '- ${Formatters.formatCurrencyPlain(discount)}',
                                style:
                                    const TextStyle(color: AppColors.success),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Delivery Charge'),
                            Text(
                              deliveryCharge > 0
                                  ? Formatters.formatCurrencyPlain(deliveryCharge)
                                  : 'Free',
                              style: TextStyle(
                                color: deliveryCharge > 0
                                    ? AppColors.textSecondary
                                    : AppColors.success,
                                fontWeight: deliveryCharge > 0
                                    ? FontWeight.normal
                                    : FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        if (_matchedArea != null && _matchedArea!.estimatedDays.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Estimated Delivery',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              Text(
                                _matchedArea!.estimatedDays,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 4),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              Formatters.formatCurrency(total),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                Text(
                  'Shipping Address',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (addressesAsync.valueOrNull != null && addressesAsync.valueOrNull!.isNotEmpty) ...[
                  SizedBox(
                    height: 110,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: addressesAsync.valueOrNull!.length + 1,
                      itemBuilder: (context, index) {
                        if (index == addressesAsync.valueOrNull!.length) {
                          final isSelected = !_useSavedAddress;
                          return _AddNewAddressCard(
                            isSelected: isSelected,
                            onTap: () {
                              setState(() {
                                _useSavedAddress = false;
                                _selectedSavedAddress = null;
                                _fullNameController.clear();
                                _phoneController.clear();
                                _provinceController.clear();
                                _districtController.clear();
                                _municipalityController.clear();
                                _streetController.clear();
                                _zipCodeController.clear();
                                _selectedProvince = null;
                                _selectedDistrict = null;
                                _selectedMunicipality = null;
                                _recalculateDeliveryCharge();
                              });
                            },
                          );
                        }

                        final address = addressesAsync.valueOrNull![index];
                        final isSelected = _useSavedAddress && _selectedSavedAddress?.id == address.id;
                        return _AddressCardItem(
                          address: address,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              _useSavedAddress = true;
                              _selectedSavedAddress = address;
                              _applySavedAddress(address);
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (!_useSavedAddress) ...[
                  Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _fullNameController,
                        onChanged: (_) => setState(() {}),
                        readOnly: _useSavedAddress && _selectedSavedAddress != null,
                        decoration: const InputDecoration(
                          labelText: 'Recipient Full Name *',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        onChanged: (_) => setState(() {}),
                        readOnly: _useSavedAddress && _selectedSavedAddress != null,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number *',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (_) => setState(() {}),
                        readOnly: _useSavedAddress && _selectedSavedAddress != null,
                        decoration: const InputDecoration(
                          labelText: 'Email Address *',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_useSavedAddress && _selectedSavedAddress != null) ...[
                        TextField(
                          controller: _provinceController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Province',
                            prefixIcon: Icon(Icons.map_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _districtController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'District',
                            prefixIcon: Icon(Icons.location_city_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _municipalityController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Municipality',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                        ),
                      ] else ...[
                        if (_allDeliveryAreas.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedProvince,
                                hint: const Text('Select Province *'),
                                items: _provinces.map((p) {
                                  return DropdownMenuItem<String>(
                                    value: p,
                                    child: Text(p),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedProvince = value;
                                    _selectedDistrict = null;
                                    _selectedMunicipality = null;
                                    _provinceController.text = value ?? '';
                                    _districtController.clear();
                                    _municipalityController.clear();
                                    _recalculateDeliveryCharge();
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedDistrict,
                                hint: const Text('Select District *'),
                                items: _districts.map((d) {
                                  return DropdownMenuItem<String>(
                                    value: d,
                                    child: Text(d),
                                  );
                                }).toList(),
                                onChanged: _selectedProvince == null
                                    ? null
                                    : (value) {
                                        setState(() {
                                          _selectedDistrict = value;
                                          _selectedMunicipality = null;
                                          _districtController.text = value ?? '';
                                          _municipalityController.clear();
                                          _recalculateDeliveryCharge();
                                        });
                                      },
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedMunicipality,
                                hint: const Text('Select Municipality *'),
                                items: _municipalities.map((m) {
                                  return DropdownMenuItem<String>(
                                    value: m,
                                    child: Text(m),
                                  );
                                }).toList(),
                                onChanged: _selectedDistrict == null
                                    ? null
                                    : (value) {
                                        setState(() {
                                          _selectedMunicipality = value;
                                          _municipalityController.text = value ?? '';
                                          _recalculateDeliveryCharge();
                                        });
                                      },
                              ),
                            ),
                          ),
                        ] else ...[
                          TextField(
                            controller: _provinceController,
                            onChanged: (_) {
                              setState(() {});
                              _recalculateDeliveryCharge();
                            },
                            decoration: const InputDecoration(
                              labelText: 'Province *',
                              prefixIcon: Icon(Icons.map_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _districtController,
                            onChanged: (_) {
                              setState(() {});
                              _recalculateDeliveryCharge();
                            },
                            decoration: const InputDecoration(
                              labelText: 'District *',
                              prefixIcon: Icon(Icons.location_city_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _municipalityController,
                            onChanged: (_) {
                              setState(() {});
                              _recalculateDeliveryCharge();
                            },
                            decoration: const InputDecoration(
                              labelText: 'Municipality *',
                              prefixIcon: Icon(Icons.location_on_outlined),
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 12),
                      TextField(
                        controller: _streetController,
                        onChanged: (_) => setState(() {}),
                        readOnly: _useSavedAddress && _selectedSavedAddress != null,
                        decoration: const InputDecoration(
                          labelText: 'Street Address *',
                          prefixIcon: Icon(Icons.home_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _zipCodeController,
                        readOnly: _useSavedAddress && _selectedSavedAddress != null,
                        decoration: const InputDecoration(
                          labelText: 'Zip Code (optional)',
                          prefixIcon: Icon(Icons.pin_outlined),
                        ),
                      ),
                      if (!_useSavedAddress && ref.watch(authProvider).status == AuthStatus.authenticated) ...[
                        const SizedBox(height: 12),
                        CheckboxListTile(
                          title: const Text('Save this address for future checkouts', style: TextStyle(fontSize: 14)),
                          value: _saveAddressChecked,
                          onChanged: (v) {
                            setState(() {
                              _saveAddressChecked = v ?? false;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                        if (_saveAddressChecked) ...[
                          const SizedBox(height: 8),
                          TextField(
                            controller: _newAddressLabelController,
                            decoration: const InputDecoration(
                              labelText: 'Address Label (e.g. Home, Office, Work) *',
                              prefixIcon: Icon(Icons.label_outline),
                            ),
                          ),
                          const SizedBox(height: 8),
                          CheckboxListTile(
                            title: const Text('Set as default address', style: TextStyle(fontSize: 14)),
                            value: _setAsDefaultChecked,
                            onChanged: (v) {
                              setState(() {
                                _setAsDefaultChecked = v ?? false;
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ],
                if (_fullNameController.text.trim().isNotEmpty &&
                    _municipalityController.text.trim().isNotEmpty &&
                    _matchedArea == null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.error_outline, color: AppColors.error),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Warning: Shipping to this area is currently not configured or unavailable.',
                            style: TextStyle(color: AppColors.error, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Order Notes (optional)',
                  ),
                ),
                const SizedBox(height: 16),
                if (_appliedCouponCode != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.local_offer,
                            size: 16, color: AppColors.success),
                        const SizedBox(width: 6),
                        Text(
                          'Coupon $_appliedCouponCode applied',
                          style: const TextStyle(
                            color: AppColors.success,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                Text(
                  'Payment Method',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                if (state.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (state.methods.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No active COD/QR payment methods available.\nPlease contact support.',
                      ),
                    ),
                  )
                else
                  Column(
                    children: state.methods
                        .map((method) {
                          final isSelected =
                              method.id == state.selectedMethodId;
                          return _PaymentMethodTile(
                            method: method,
                            isSelected: isSelected,
                            onTap: () => ref
                                .read(paymentSelectionProvider.notifier)
                                .selectMethod(method.id),
                          );
                        })
                        .toList(),
                  ),
                const SizedBox(height: 12),
                if (selected != null)
                  _buildSelectedMethodDetails(selected, state),
                const SizedBox(height: 92),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                top: false,
                child: ElevatedButton(
                  onPressed: state.isSubmitting ||
                          !_validateFields() ||
                          !state.canCheckout
                      ? null
                      : _completeCheckout,
                  child: Text(
                      'Place Order${discountRate != null ? ' (${discountRate.round()}% off)' : ''}'),
                ),
              ),
            ),
          ),
          if (state.isSubmitting)
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

  Widget _buildSelectedMethodDetails(
    PaymentMethod method,
    PaymentSelectionState state,
  ) {
    if (method.isCod) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(14),
          child: Text('Pay with cash upon delivery'),
        ),
      );
    }

    if (method.isQr) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (method.qrImage != null && method.qrImage!.isNotEmpty) ...[
                Center(
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(12),
                          child: Image.network(
                            _resolveImageUrl(method.qrImage!),
                            height: 250,
                            width: 250,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => _downloadQrCode(_resolveImageUrl(method.qrImage!)),
                        icon: const Icon(Icons.download_rounded, size: 20),
                        label: const Text('Save QR Code to Gallery'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              if (method.accountName != null && method.accountName!.isNotEmpty) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Account Name: ${method.accountName}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primary),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: method.accountName!));
                        AppToast.showSuccess(context, 'Account Name copied!');
                      },
                      tooltip: 'Copy Account Name',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (method.accountNumber != null && method.accountNumber!.isNotEmpty) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Account Number: ${method.accountNumber}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primary),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: method.accountNumber!));
                        AppToast.showSuccess(context, 'Account Number copied!');
                      },
                      tooltip: 'Copy Account Number',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (method.instructions != null && method.instructions!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(method.instructions!),
              ],
              const SizedBox(height: 14),
              const Text(
                'Upload Payment Screenshot',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickScreenshot,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(
                  state.screenshotPath == null
                      ? 'Choose from gallery'
                      : 'Change screenshot',
                ),
              ),
              if (state.screenshotPath != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    File(state.screenshotPath!),
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final PaymentMethod method;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodTile({
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 1.5 : 0.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected ? AppColors.primary : AppColors.textHint,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.title,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    Text(
                      method.isCod ? 'Cash on delivery' : 'QR transfer',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _AddressCardItem extends StatelessWidget {
  final Address address;
  final bool isSelected;
  final VoidCallback onTap;

  const _AddressCardItem({
    required this.address,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    IconData getIcon() {
      switch (address.label.toLowerCase()) {
        case 'home':
          return Icons.home_outlined;
        case 'office':
        case 'work':
          return Icons.work_outlined;
        default:
          return Icons.location_on_outlined;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2.0 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        getIcon(),
                        size: 16,
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          address.label,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    size: 16,
                    color: AppColors.primary,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              address.fullName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              address.displayText,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddNewAddressCard extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _AddNewAddressCard({
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2.0 : 1.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_location_alt_outlined,
              size: 28,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              'Add New Address',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
