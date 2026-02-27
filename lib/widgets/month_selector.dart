import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MonthSelector extends StatelessWidget {
  const MonthSelector({
    super.key,
    required this.year,
    required this.month,
    required this.onChanged,
  });

  final int year;
  final int month;
  final void Function(int year, int month) onChanged;

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton.filled(
            onPressed: () {
              var m = month - 1, y = year;
              if (m < 1) { m = 12; y--; }
              onChanged(y, m);
            },
            icon: const Icon(Icons.chevron_left_rounded, size: 24),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.outline.withValues(alpha: 0.5),
              foregroundColor: AppTheme.onSurface,
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                '${_months[month - 1]} $year',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                ),
              ),
            ),
          ),
          IconButton.filled(
            onPressed: () {
              var m = month + 1, y = year;
              if (m > 12) { m = 1; y++; }
              onChanged(y, m);
            },
            icon: const Icon(Icons.chevron_right_rounded, size: 24),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.outline.withValues(alpha: 0.5),
              foregroundColor: AppTheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
