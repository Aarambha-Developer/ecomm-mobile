import 'package:aarambha_app/core/network/api_client.dart';
import 'package:aarambha_app/features/checkout/data/datasources/checkout_remote_source.dart';
import 'package:aarambha_app/features/checkout/data/models/payment_method.dart';

class CheckoutRepository {
  final CheckoutRemoteSource _remoteSource;

  CheckoutRepository(ApiClient client)
      : _remoteSource = CheckoutRemoteSource(client);

  Future<List<PaymentMethod>> getPaymentMethods() async {
    return await _remoteSource.getActivePaymentMethods();
  }

  Future<CheckoutResult> placeOrder({
    required String shippingAddress,
    required String paymentMethodId,
    String? notes,
    String? couponCode,
    String? paymentScreenshotPath,
  }) async {
    final response = await _remoteSource.placeOrder(
      shippingAddress: shippingAddress,
      paymentMethodId: paymentMethodId,
      notes: notes,
      couponCode: couponCode,
      paymentScreenshotPath: paymentScreenshotPath,
    );
    return CheckoutResult.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<double> validateCoupon({
    required String code,
    required String cartTotal,
    required List<String> productIds,
  }) async {
    final response = await _remoteSource.validateCoupon(
      code: code,
      cartTotal: cartTotal,
      productIds: productIds,
    );
    final data = response['data'] as Map<String, dynamic>;
    final rate = data['discount_rate'];
    if (rate is num) return rate.toDouble();
    return double.tryParse(rate.toString()) ?? 0;
  }
}

class CheckoutResult {
  final String? orderId;
  final String? paymentUrl;
  final bool requiresGatewayRedirect;

  const CheckoutResult({
    this.orderId,
    this.paymentUrl,
    this.requiresGatewayRedirect = false,
  });

  factory CheckoutResult.fromJson(Map<String, dynamic> json) {
    final hasGateway = json['payment_gateway'] is Map;
    String? paymentUrl;
    if (hasGateway) {
      final gateway = Map<String, dynamic>.from(json['payment_gateway'] as Map);
      paymentUrl = gateway['payment_url'] as String?;
    }
    return CheckoutResult(
      orderId: json['id']?.toString(),
      paymentUrl: paymentUrl,
      requiresGatewayRedirect: paymentUrl != null,
    );
  }
}
