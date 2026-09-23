import 'package:intl/intl.dart';

final _inr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

/// "700.00" → "₹700.00". Never throws — falls back to a plain ₹ prefix.
String inr(Object? value) {
  if (value == null) return '₹0.00';
  final n = double.tryParse(value.toString());
  if (n == null) return '₹$value';
  return _inr.format(n);
}

String dateTime(Object? value) {
  if (value == null) return '';
  final dt = DateTime.tryParse(value.toString());
  if (dt == null) return value.toString();
  return DateFormat('d MMM, h:mm a').format(dt.toLocal());
}
