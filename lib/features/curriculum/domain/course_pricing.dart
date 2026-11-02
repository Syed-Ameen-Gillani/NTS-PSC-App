/// Persisted amounts use whole Pakistani rupees; fractional input is rejected.
abstract final class CoursePricing {
  static const currency = 'PKR';
  static const maximumAmount = 1000000;

  static int? parsePaidAmount(String value) {
    final text = value.trim();
    if (!RegExp(r'^[0-9]+$').hasMatch(text)) return null;
    final amount = int.tryParse(text);
    return amount != null && amount > 0 && amount <= maximumAmount
        ? amount
        : null;
  }

  static String label(int amount) => amount == 0 ? 'Free' : 'Rs $amount';
}
