import 'package:flutter/foundation.dart';
import '../models/pay_period_config.dart';

class PayPeriodStore extends ChangeNotifier {
  int _period1EndDay = 14;
  DateTime? _firstPeriodStartDate;
  int _periodLengthDays = 14;

  int get period1EndDay => _period1EndDay;

  set period1EndDay(int value) {
    if (value < 1 || value > 28) return;
    _period1EndDay = value;
    notifyListeners();
  }

  DateTime? get firstPeriodStartDate => _firstPeriodStartDate;

  set firstPeriodStartDate(DateTime? value) {
    _firstPeriodStartDate = value;
    notifyListeners();
  }

  int get periodLengthDays => _periodLengthDays;

  set periodLengthDays(int value) {
    if (value < 1 || value > 31) return;
    _periodLengthDays = value;
    notifyListeners();
  }

  bool get isCustom => _firstPeriodStartDate != null;

  PayPeriodConfig get config => PayPeriodConfig(
        period1EndDay: _period1EndDay,
        firstPeriodStartDate: _firstPeriodStartDate,
        periodLengthDays: _periodLengthDays,
      );
}
