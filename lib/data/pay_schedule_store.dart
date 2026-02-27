import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../models/pay_schedule_config.dart';
import 'local_db.dart';

/// Pay schedule: anchor date + 14-day interval. Periods generated sequentially; start/end are source of truth.
class PayScheduleStore extends ChangeNotifier {
  PayScheduleStore() {
    _loadFromDb();
  }

  DateTime? _startDate;
  int _periodLengthDays = 14;
  MonthInclusionPolicy _monthInclusionPolicy = MonthInclusionPolicy.startMonth;

  DateTime? get startDate => _startDate;
  set startDate(DateTime? v) {
    _startDate = v;
    _saveToDb();
    notifyListeners();
  }

  int get periodLengthDays => _periodLengthDays;
  set periodLengthDays(int v) {
    _periodLengthDays = v.clamp(7, 31);
    _saveToDb();
    notifyListeners();
  }

  MonthInclusionPolicy get monthInclusionPolicy => _monthInclusionPolicy;
  set monthInclusionPolicy(MonthInclusionPolicy v) {
    _monthInclusionPolicy = v;
    _saveToDb();
    notifyListeners();
  }

  PayScheduleConfig get config => PayScheduleConfig(
        startDate: _startDate,
        periodLengthDays: _periodLengthDays,
      );

  Future<void> _loadFromDb() async {
    final db = await LocalDb.instance.database;
    final rows = await db.query('pay_schedule', limit: 1);
    if (rows.isEmpty) {
      _startDate = null;
      _periodLengthDays = 14;
      _monthInclusionPolicy = MonthInclusionPolicy.startMonth;
      notifyListeners();
      return;
    }
    final row = rows.first;
    final startDateStr = row['start_date'] as String?;
    _startDate = startDateStr != null && startDateStr.isNotEmpty
        ? DateTime.tryParse(startDateStr)
        : null;
    _periodLengthDays = (row['period_length_days'] as int?) ?? 14;
    final policyIndex = row['month_inclusion_policy'] as int?;
    _monthInclusionPolicy = policyIndex != null && policyIndex >= 0 && policyIndex < MonthInclusionPolicy.values.length
        ? MonthInclusionPolicy.values[policyIndex]
        : MonthInclusionPolicy.startMonth;
    notifyListeners();
  }

  /// Reload pay schedule from the database (e.g. after a data reset).
  Future<void> reload() => _loadFromDb();

  Future<void> _saveToDb() async {
    final db = await LocalDb.instance.database;
    await db.insert(
      'pay_schedule',
      {
        'id': 1,
        'start_date': _startDate?.toIso8601String(),
        'period_length_days': _periodLengthDays,
        'month_inclusion_policy': _monthInclusionPolicy.index,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
