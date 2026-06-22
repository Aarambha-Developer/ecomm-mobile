import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aarambha_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:aarambha_app/features/checkout/data/models/payment_method.dart';
import 'package:aarambha_app/features/checkout/data/repositories/checkout_repository.dart';

final checkoutRepositoryProvider = Provider<CheckoutRepository>((ref) {
  return CheckoutRepository(ref.read(apiClientProvider));
});

final paymentMethodsProvider = FutureProvider<List<PaymentMethod>>((ref) async {
  final repo = ref.read(checkoutRepositoryProvider);
  return await repo.getPaymentMethods();
});