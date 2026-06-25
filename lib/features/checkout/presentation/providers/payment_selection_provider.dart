import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aarambha_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:aarambha_app/features/checkout/data/models/order_request.dart';
import 'package:aarambha_app/features/checkout/data/models/payment_method.dart';
import 'package:aarambha_app/features/checkout/data/services/payment_api_service.dart';

final paymentApiServiceProvider = Provider<PaymentApiService>((ref) {
  return PaymentApiService(ref.read(apiClientProvider));
});

class PaymentSelectionState {
  final bool isLoading;
  final bool isSubmitting;
  final bool isValidatingCoupon;
  final String? validatingCouponCode;
  final List<PaymentMethod> methods;
  final String? selectedMethodId;
  final String? screenshotPath;
  final String? errorMessage;
  final double? couponDiscountRate;

  const PaymentSelectionState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.isValidatingCoupon = false,
    this.validatingCouponCode,
    this.methods = const [],
    this.selectedMethodId,
    this.screenshotPath,
    this.errorMessage,
    this.couponDiscountRate,
  });

  PaymentSelectionState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    bool? isValidatingCoupon,
    String? validatingCouponCode,
    bool clearValidatingCoupon = false,
    List<PaymentMethod>? methods,
    String? selectedMethodId,
    bool clearSelectedMethod = false,
    String? screenshotPath,
    bool clearScreenshot = false,
    String? errorMessage,
    bool clearError = false,
    double? couponDiscountRate,
    bool clearCouponRate = false,
  }) {
    return PaymentSelectionState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isValidatingCoupon: isValidatingCoupon ?? this.isValidatingCoupon,
      validatingCouponCode: clearValidatingCoupon
          ? null
          : (validatingCouponCode ?? this.validatingCouponCode),
      methods: methods ?? this.methods,
      selectedMethodId: clearSelectedMethod
          ? null
          : (selectedMethodId ?? this.selectedMethodId),
      screenshotPath:
          clearScreenshot ? null : (screenshotPath ?? this.screenshotPath),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      couponDiscountRate: clearCouponRate
          ? null
          : (couponDiscountRate ?? this.couponDiscountRate),
    );
  }

  PaymentMethod? get selectedMethod {
    if (selectedMethodId == null) return null;
    for (final method in methods) {
      if (method.id == selectedMethodId) return method;
    }
    return null;
  }

  bool get canCheckout {
    final method = selectedMethod;
    if (method == null) return false;
    if (method.isQr && (screenshotPath == null || screenshotPath!.isEmpty)) {
      return false;
    }
    return true;
  }
}

class PaymentSelectionNotifier extends StateNotifier<PaymentSelectionState> {
  final PaymentApiService _service;

  PaymentSelectionNotifier(this._service)
      : super(const PaymentSelectionState(isLoading: true)) {
    loadMethods();
  }

  Future<void> loadMethods() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final methods = await _service.fetchActiveMethods();
      state = state.copyWith(
        isLoading: false,
        methods: methods,
        selectedMethodId: methods.isNotEmpty ? methods.first.id : null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void selectMethod(String methodId) {
    final selected =
        state.methods.where((method) => method.id == methodId).firstOrNull;
    state = state.copyWith(
      selectedMethodId: methodId,
      clearScreenshot: selected?.isCod == true,
      clearError: true,
    );
  }

  void setScreenshotPath(String? path) {
    state = state.copyWith(screenshotPath: path, clearError: true);
  }

  void applyCouponLocally(double rate) {
    state = state.copyWith(couponDiscountRate: rate, clearError: true);
  }

  void clearCoupon() {
    state = state.copyWith(clearCouponRate: true);
  }

  Future<double?> validateCoupon(String code) async {
    if (code.isEmpty) return null;

    state = state.copyWith(
      isValidatingCoupon: true,
      validatingCouponCode: code,
      clearError: true,
    );

    try {
      final rate = await _service.validateCoupon(code);
      state = state.copyWith(
        isValidatingCoupon: false,
        couponDiscountRate: rate,
      );
      return rate;
    } catch (e) {
      state = state.copyWith(
        isValidatingCoupon: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  Future<String?> completeCheckout({
    required OrderRequest orderRequest,
    String? couponCode,
  }) async {
    final method = state.selectedMethod;
    if (method == null) {
      state = state.copyWith(errorMessage: 'Please select a payment method');
      return null;
    }
    if (method.isQr &&
        (state.screenshotPath == null || state.screenshotPath!.isEmpty)) {
      state = state.copyWith(
        errorMessage: 'Payment screenshot is required for QR payments',
      );
      return null;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final orderId = await _service.createOrder(
        paymentMethodId: method.id,
        request: orderRequest,
        couponCode: couponCode,
        screenshotPath: method.isQr ? state.screenshotPath : null,
      );

      state = state.copyWith(isSubmitting: false);
      return orderId;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
      return null;
    }
  }
}

final paymentSelectionProvider = StateNotifierProvider<
    PaymentSelectionNotifier, PaymentSelectionState>((ref) {
  return PaymentSelectionNotifier(ref.read(paymentApiServiceProvider));
});
