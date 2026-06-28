class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://ecom.aitrc.com.np/api/v1';

  static const Duration timeout = Duration(seconds: 30);
  static const Duration refreshTimeout = Duration(seconds: 15);

  // Auth
  static const String login = '/auth/login/';
  static const String register = '/auth/register/';
  static const String logout = '/auth/logout/';
  static const String refreshToken = '/auth/refresh/';
  static const String me = '/auth/me/';
  static const String googleLogin = '/auth/google/';
  static const String appleLogin = '/auth/apple/';
  static const String resendVerification = '/auth/resend-verification/';
  static const String requestSmsOtp = '/auth/request-sms-otp/';
  static const String verifyEmail = '/auth/verify-email/confirm/';
  static const String verifyPhone = '/auth/verify-phone/confirm/';
  static const String passwordResetRequest = '/auth/password-reset/request/';
  static const String passwordResetConfirm = '/auth/password-reset/confirm/';

  // Catalog
  static const String brands = '/brands/';
  static const String adminBrands = '/admin/brands/';
  static const String categories = '/categories/';
  static const String adminCategories = '/admin/categories/';
  static const String products = '/products/';
  static const String adminProducts = '/admin/products/';
  static const String reviews = '/reviews/';
  static const String adminReviews = '/admin/reviews/';

  // Commerce
  static const String cart = '/cart/';
  static const String cartItems = '/cart/items/';
  static const String cartClear = '/cart/clear/';
  static const String wishlist = '/wishlist/';
  static const String wishlistItems = '/wishlist/items/';
  static const String wishlistClear = '/wishlist/clear/';
  static const String orders = '/orders/';
  static const String ordersRecent = '/orders/recent/';
  static const String checkout = '/orders/checkout/';
  static const String adminOrders = '/admin/orders/';

  // Payments
  static const String activePaymentMethods = '/payments/methods/active/';
  static const String paymentProofsMe = '/payments/proofs/me/';
  static const String esewaVerify = '/payments/esewa/verify/';
  static const String khaltiVerify = '/payments/khalti/verify/';
  static const String adminPaymentMethods = '/admin/payment-methods/';
  static const String adminPaymentProofs = '/admin/payment-proofs/';

  // Marketing
  static const String offers = '/offers/';
  static const String adminOffers = '/admin/offers/';
  static const String hero = '/hero/';
  static const String adminHero = '/admin/hero/';
  static const String adminHeroSlides = '/admin/hero-slides/';

  // Coupons
  static const String validateCoupon = '/coupons/validate/';
  static const String adminCoupons = '/admin/coupons/';

  // Profile
  // NOTE: The /auth/password/change/ endpoint does not exist in the current API spec.
  static const String changePassword = '/auth/me/change-password/';

  // Addresses
  // NOTE: The /addresses/ endpoint does not exist in the current API spec.
  static const String addresses = '/addresses/';

  // Contact
  static const String contact = '/contact/';
  static const String adminContacts = '/admin/contacts/';
}
