import 'package:dio/dio.dart';

import 'package:aarambha_app/core/constants/api_constants.dart';
import 'package:aarambha_app/core/network/api_client.dart';
import 'package:aarambha_app/features/checkout/data/models/order_request.dart';
import 'package:aarambha_app/features/checkout/data/models/payment_method.dart';

class PaymentApiService {
  final ApiClient _client;

  PaymentApiService(this._client);

  Future<List<PaymentMethod>> fetchActiveMethods() async {
    final response = await _client.get(ApiConstants.activePaymentMethods);
    final data = response['data'];

    List<dynamic> raw = [];
    if (data is List) {
      raw = data;
    } else if (data is Map && data['results'] is List) {
      raw = data['results'] as List;
    } else if (response is List) {
      raw = response as List<dynamic>;
    } else if (response.containsKey('results') &&
        response['results'] is List) {
      raw = response['results'] as List;
    } else if (data is Map && data.isNotEmpty) {
      raw = [Map<String, dynamic>.from(data)];
    }

    return raw
        .whereType<Map<Object?, Object?>>()
        .map((e) => PaymentMethod.fromJson(
              Map<String, dynamic>.from(e),
            ))
        .where((method) => method.type == 'cod' || method.type == 'qr')
        .toList();
  }

  Future<double> validateCoupon({
    required String code,
    required String cartTotal,
    required List<String> productIds,
  }) async {
    final response = await _client.post(
      ApiConstants.validateCoupon,
      data: {
        'code': code,
        'cart_total': cartTotal,
        'product_ids': productIds,
      },
    );

    Map<String, dynamic> parsed = response;
    if (response.containsKey('data') && response['data'] is Map) {
      parsed = Map<String, dynamic>.from(response['data'] as Map);
    }

    final rate = parsed['discount_rate'] ??
        parsed['discount_percent'] ??
        parsed['discount_value'] ??
        parsed['discount_amount'] ??
        parsed['rate'] ??
        parsed['value'];

    if (rate == null) {
      if (response != parsed) {
        final rootRate = response['discount_rate'] ??
            response['discount_percent'] ??
            response['discount_value'] ??
            response['discount_amount'] ??
            response['rate'] ??
            response['value'];
        if (rootRate != null) {
          if (rootRate is num) return rootRate.toDouble();
          return double.tryParse(rootRate.toString()) ?? 0.0;
        }
      }
      throw Exception(
        'Coupon validated but no discount rate returned. '
        'Response: $response',
      );
    }

    if (rate is num) return rate.toDouble();
    final parsed2 = double.tryParse(rate.toString());
    if (parsed2 != null) return parsed2;
    throw Exception('Could not parse coupon discount rate: $rate');
  }

  Future<String> createOrder({
    required String paymentMethodId,
    required OrderRequest request,
    String? couponCode,
    String? screenshotPath,
  }) async {
    if (screenshotPath != null && screenshotPath.isNotEmpty) {
      final formData = FormData.fromMap({
        'shipping_address': request.shippingAddress,
        'payment_method': paymentMethodId,
        if (request.notes.isNotEmpty) 'notes': request.notes,
        if (couponCode != null && couponCode.trim().isNotEmpty)
          'coupon_code': couponCode.trim(),
        'payment_screenshot': await MultipartFile.fromFile(screenshotPath),
      });

      final response = await _client.upload(
        ApiConstants.checkout,
        data: formData,
      );

      final data = response['data'];
      if (data is Map) {
        final id = data['id']?.toString();
        if (id != null && id.isNotEmpty) return id;
        final orderNumber = data['order_number']?.toString();
        if (orderNumber != null && orderNumber.isNotEmpty) return orderNumber;
      }
      throw Exception('Could not parse created order id');
    }

    final payload = <String, dynamic>{
      ...request.toJson(),
      'payment_method': paymentMethodId,
      if (couponCode != null && couponCode.trim().isNotEmpty)
        'coupon_code': couponCode.trim(),
    };

    final response = await _client.post(
      ApiConstants.checkout,
      data: payload,
    );

    final data = response['data'];
    if (data is Map) {
      final id = data['id']?.toString();
      if (id != null && id.isNotEmpty) return id;
      final orderNumber = data['order_number']?.toString();
      if (orderNumber != null && orderNumber.isNotEmpty) return orderNumber;
    }

    throw Exception('Could not parse created order id');
  }

  Future<void> uploadPaymentProof({
    required String orderId,
    required String screenshotPath,
  }) async {
    final formData = FormData.fromMap({
      'order': orderId,
      'screenshot': await MultipartFile.fromFile(screenshotPath),
    });

    await _client.upload(ApiConstants.paymentProofsMe, data: formData);
  }
}
