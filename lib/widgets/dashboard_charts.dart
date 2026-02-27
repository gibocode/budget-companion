import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../data/category_store.dart';
import '../data/expense_store.dart';
import '../data/transaction_store.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/icon_colors.dart';

/// Dashboard charts section: pie (expense breakdown), trend line (6 months), bar (monthly comparison).
class DashboardCharts extends StatelessWidget {
  const DashboardCharts({
    super.key,
    required this.selectedYear,
    required this.selectedMonth,
  });

  final int selectedYear;
  final int selectedMonth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PieChartCard(
            selectedYear: selectedYear,
            selectedMonth: selectedMonth,
          ),
          const SizedBox(height: 16),
          _TrendLineCard(
            selectedYear: selectedYear,
            selectedMonth: selectedMonth,
          ),
          const SizedBox(height: 16),
          _BarChartCard(
            selectedYear: selectedYear,
            selectedMonth: selectedMonth,
          ),
        ],
      ),
    );
  }
}

class _PieChartCard extends StatelessWidget {
  const _PieChartCard({
    required this.selectedYear,
    required this.selectedMonth,
  });

  final int selectedYear;
  final int selectedMonth;

  @override
  Widget build(BuildContext context) {
    final txStore = context.watch<TransactionStore>();
    final categoryStore = context.watch<CategoryStore>();
    final expenseStore = context.watch<ExpenseStore>();

    final expenses = txStore
        .forMonth(selectedYear, selectedMonth)
        .where((t) => t.type == TransactionType.expense)
        .toList();

    final byRef = <String, double>{};
    for (final t in expenses) {
      byRef[t.referenceId] = (byRef[t.referenceId] ?? 0) + t.amount;
    }

    final entries = byRef.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (entries.isEmpty) {
      return _ChartCard(
        title: 'Expenses this month',
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No expenses this month',
              style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant),
            ),
          ),
        ),
      );
    }

    double total = entries.fold(0.0, (s, e) => s + e.value);
    final sections = <PieChartSectionData>[];
    for (int i = 0; i < entries.length; i++) {
      final e = entries[i];
      String label = categoryStore.byId(e.key)?.name ??
          expenseStore.byId(e.key)?.name ??
          e.key;
      if (label.length > 12) label = '${label.substring(0, 10)}…';
      final color = colorForIndex(i);
      sections.add(
        PieChartSectionData(
          value: e.value,
          color: color,
          title: total > 0 && e.value / total >= 0.05 ? label : '',
          showTitle: true,
          titleStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          radius: 48,
        ),
      );
    }

    return _ChartCard(
      title: 'Expenses this month',
      child: SizedBox(
        height: 200,
        child: Row(
          children: [
            SizedBox(
              width: 160,
              height: 160,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 28,
                  sectionsSpace: 1,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: entries.length,
                itemBuilder: (context, i) {
                  final e = entries[i];
                  final pct = total > 0 ? (e.value / total * 100).round() : 0;
                  final name = categoryStore.byId(e.key)?.name ??
                      expenseStore.byId(e.key)?.name ??
                      e.key;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: colorForIndex(i),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${formatPesoCompact(e.value)} ($pct%)',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendLineCard extends StatelessWidget {
  const _TrendLineCard({
    required this.selectedYear,
    required this.selectedMonth,
  });

  final int selectedYear;
  final int selectedMonth;

  static const _monthsCount = 6;

  @override
  Widget build(BuildContext context) {
    final txStore = context.watch<TransactionStore>();

    final months = <_MonthPoint>[];
    for (int i = _monthsCount - 1; i >= 0; i--) {
      int m = selectedMonth - i;
      int y = selectedYear;
      while (m < 1) {
        m += 12;
        y--;
      }
      while (m > 12) {
        m -= 12;
        y++;
      }
      final expense = txStore.totalActualForMonthByType(
          y, m, TransactionType.expense);
      final income = txStore.totalActualForMonthByType(
          y, m, TransactionType.income);
      final label = _shortMonth(m);
      months.add(_MonthPoint(year: y, month: m, label: label, expense: expense, income: income));
    }

    final maxVal = months.fold<double>(
      0,
      (s, p) {
        final m = p.expense > p.income ? p.expense : p.income;
        return m > s ? m : s;
      },
    );
    final maxY = maxVal <= 0 ? 1.0 : maxVal * 1.15;

    final expenseSpots = months.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.expense)).toList();
    final incomeSpots = months.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.income)).toList();

    return _ChartCard(
      title: 'Last $_monthsCount months trend',
      child: SizedBox(
        height: 180,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY,
            minX: 0,
            maxX: (months.length - 1).toDouble(),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY / 4,
              getDrawingHorizontalLine: (v) => FlLine(
                color: AppTheme.outline.withValues(alpha: 0.3),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false, reservedSize: 0)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false, reservedSize: 0)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false, reservedSize: 0)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  interval: 1,
                  getTitlesWidget: (v, meta) {
                    final i = v.toInt();
                    if (i >= 0 && i < months.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          months[i].label,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: expenseSpots,
                isCurved: true,
                color: AppTheme.error,
                barWidth: 2.5,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppTheme.error.withValues(alpha: 0.15),
                ),
              ),
              LineChartBarData(
                spots: incomeSpots,
                isCurved: true,
                color: AppTheme.success,
                barWidth: 2.5,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppTheme.success.withValues(alpha: 0.15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _shortMonth(int m) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return names[m - 1];
  }
}

class _MonthPoint {
  _MonthPoint({
    required this.year,
    required this.month,
    required this.label,
    required this.expense,
    required this.income,
  });
  final int year;
  final int month;
  final String label;
  final double expense;
  final double income;
}

class _BarChartCard extends StatelessWidget {
  const _BarChartCard({
    required this.selectedYear,
    required this.selectedMonth,
  });

  final int selectedYear;
  final int selectedMonth;

  static const _monthsCount = 6;

  @override
  Widget build(BuildContext context) {
    final txStore = context.watch<TransactionStore>();

    final months = <_MonthPoint>[];
    for (int i = _monthsCount - 1; i >= 0; i--) {
      int m = selectedMonth - i;
      int y = selectedYear;
      while (m < 1) {
        m += 12;
        y--;
      }
      while (m > 12) {
        m -= 12;
        y++;
      }
      final expense = txStore.totalActualForMonthByType(
          y, m, TransactionType.expense);
      final income = txStore.totalActualForMonthByType(
          y, m, TransactionType.income);
      final label = _shortMonth(m);
      months.add(_MonthPoint(year: y, month: m, label: label, expense: expense, income: income));
    }

    final maxVal = months.fold<double>(
      0,
      (s, p) {
        final m = p.expense > p.income ? p.expense : p.income;
        return m > s ? m : s;
      },
    );
    final maxY = maxVal <= 0 ? 1.0 : maxVal * 1.2;

    final groups = months.asMap().entries.map((e) {
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: e.value.expense,
            color: AppTheme.error,
            width: 10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: e.value.income,
            color: AppTheme.success,
            width: 10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
        barsSpace: 6,
      );
    }).toList();

    return _ChartCard(
      title: 'Monthly comparison',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(AppTheme.error, 'Expenses'),
              const SizedBox(width: 16),
              _legendDot(AppTheme.success, 'Income'),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                minY: 0,
                barGroups: groups,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: AppTheme.outline.withValues(alpha: 0.3),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false, reservedSize: 0)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false, reservedSize: 0)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false, reservedSize: 0)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (v, meta) {
                        final i = v.toInt();
                        if (i >= 0 && i < months.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              months[i].label,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _shortMonth(int m) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return names[m - 1];
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
