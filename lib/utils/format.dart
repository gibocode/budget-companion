import 'package:intl/intl.dart';

/// Philippine Peso sign (Unicode U+20B1)
const String pesoSign = '₱';

final _pesoFormat = NumberFormat.currency(
  locale: 'en_PH',
  symbol: pesoSign,
  decimalDigits: 2,
);

String formatPeso(double amount) => _pesoFormat.format(amount);

String formatPesoCompact(double amount) {
  if (amount >= 1000) {
    return '$pesoSign${NumberFormat('#,##0.00', 'en_PH').format(amount)}';
  }
  return _pesoFormat.format(amount);
}
