class Formatters {
  Formatters._();

  static const String _currencySymbol = 'Rs.';

  static String formatCurrency(double amount) {
    final rounded = amount == amount.roundToDouble();
    return '$_currencySymbol ${amount.toStringAsFixed(rounded ? 0 : 2)}';
  }

  static String formatCurrencyPlain(double amount) {
    return '$_currencySymbol ${amount.toStringAsFixed(2)}';
  }
}