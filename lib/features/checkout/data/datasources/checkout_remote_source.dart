import 'package:aarambha_app/core/network/api_client.dart';
import 'package:aarambha_app/core/constants/api_constants.dart';
import 'package:aarambha_app/features/checkout/data/models/payment_method.dart';
import 'package:dio/dio.dart';

class CheckoutRemoteSource {
  final ApiClient _client;

  CheckoutRemoteSource(this._client);

  Future<List<PaymentMethod>> getActivePaymentMethods() async {
    final response = await _client.get(ApiConstants.activePaymentMethods);
    final data = response['data'];
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map((e) => PaymentMethod.fromJson(e))
          .toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> placeOrder({
    required String shippingAddress,
    required String paymentMethodId,
    String? notes,
    String? couponCode,
    String? paymentScreenshotPath,
  }) async {
    if (paymentScreenshotPath != null) {
      final formData = FormData.fromMap({
        'shipping_address': shippingAddress,
        'payment_method': paymentMethodId,
        if (notes != null) 'notes': notes,
        if (couponCode != null) 'coupon_code': couponCode,
        if (paymentScreenshotPath.isNotEmpty)
          'payment_screenshot': await MultipartFile.fromFile(
            paymentScreenshotPath,
          ),
      });
      return await _client.upload(ApiConstants.checkout, data: formData);
    }

    return await _client.post(
      ApiConstants.checkout,
      data: {
        'shipping_address': shippingAddress,
        'payment_method': paymentMethodId,
        if (notes != null) 'notes': notes,
        if (couponCode != null) 'coupon_code': couponCode,
      },
    );
  }

  Future<Map<String, dynamic>> validateCoupon(String code) async {
    return await _client.post(
      ApiConstants.validateCoupon,
      data: {'code': code},
    );
  }
}
