/// Pay period config: fixed (1–N, N+1–end) or custom (start date + length in days).
class PayPeriodConfig {
  const PayPeriodConfig({
    this.period1EndDay = 14,
    this.firstPeriodStartDate,
    this.periodLengthDays = 14,
  });

  /// For fixed mode: period 1 = 1 to period1EndDay, period 2 = period1EndDay+1 to end of month.
  final int period1EndDay;

  /// For custom mode: first period starts on this date; then each period is [periodLengthDays] long.
  final DateTime? firstPeriodStartDate;

  final int periodLengthDays;

  bool get isCustom => firstPeriodStartDate != null;

  int lastDayOfMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  static String monthName(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return names[month - 1];
  }

  /// Period 1 date range for the given month (e.g. "Feb 1–14" or "Jan 30–Feb 12" for custom).
  String period1DateRange(int year, int month) {
    if (isCustom && firstPeriodStartDate != null) {
      final (start, end) = _period1RangeInMonth(year, month);
      if (start == null) return '${monthName(month)} 1–${period1EndDay}';
      final monthStart = DateTime(year, month, 1);
      final monthEnd = DateTime(year, month, lastDayOfMonth(year, month));
      final s = start.isBefore(monthStart) ? 1 : start.day;
      final e = end != null
          ? (end.isAfter(monthEnd) ? lastDayOfMonth(year, month) : end.day)
          : lastDayOfMonth(year, month);
      return '${monthName(month)} $s–$e';
    }
    return '${monthName(month)} 1–$period1EndDay';
  }

  /// Period 2 date range for the given month.
  String period2DateRange(int year, int month) {
    if (isCustom && firstPeriodStartDate != null) {
      final (_, end1) = _period1RangeInMonth(year, month);
      if (end1 == null) {
        final last = lastDayOfMonth(year, month);
        return '${monthName(month)} ${period1EndDay + 1}–$last';
      }
      final start2 = end1.add(const Duration(days: 1));
      final end2 = start2.add(Duration(days: periodLengthDays - 1));
      final monthStart = DateTime(year, month, 1);
      final monthEnd = DateTime(year, month, lastDayOfMonth(year, month));
      final s = start2.isBefore(monthStart) ? 1 : start2.day;
      final e = end2.isAfter(monthEnd) ? lastDayOfMonth(year, month) : end2.day;
      return '${monthName(month)} $s–$e';
    }
    final last = lastDayOfMonth(year, month);
    return '${monthName(month)} ${period1EndDay + 1}–$last';
  }

  (DateTime?, DateTime?) _period1RangeInMonth(int year, int month) {
    var p1Start = DateTime(
      firstPeriodStartDate!.year,
      firstPeriodStartDate!.month,
      firstPeriodStartDate!.day,
    );
    final monthStart = DateTime(year, month, 1);
    while (p1Start.add(Duration(days: periodLengthDays)).isBefore(monthStart)) {
      p1Start = p1Start.add(Duration(days: periodLengthDays));
    }
    final p1End = p1Start.add(Duration(days: periodLengthDays - 1));
    final monthEnd = DateTime(year, month, lastDayOfMonth(year, month));
    if (p1End.isBefore(monthStart) || p1Start.isAfter(monthEnd)) {
      return (null, null);
    }
    return (p1Start, p1End);
  }

  /// Which period (1 or 2) a day falls in for the given month. [day] is 1-based day of month.
  int periodForDay(int year, int month, int day) {
    if (isCustom && firstPeriodStartDate != null) {
      final d = DateTime(year, month, day);
      final (p1Start, p1End) = _period1RangeInMonth(year, month);
      if (p1Start == null) return day <= period1EndDay ? 1 : 2;
      if (!d.isBefore(p1Start) && !d.isAfter(p1End!)) return 1;
      return 2;
    }
    return day <= period1EndDay ? 1 : 2;
  }
}
