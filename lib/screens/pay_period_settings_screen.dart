import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/pay_schedule_store.dart';
import '../models/pay_schedule_config.dart';
import '../theme/app_theme.dart';

class PayPeriodSettingsScreen extends StatelessWidget {
  const PayPeriodSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PayScheduleStore>();
    final config = store.config;
    final sampleDate = store.startDate ?? DateTime.now();
    final sampleYear = sampleDate.year;
    final sampleMonth = sampleDate.month;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pay period'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SettingsSection(
            title: 'Pay period',
            children: [
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.event_rounded,
                    color: AppTheme.primary,
                    size: 22,
                  ),
                ),
                title: const Text('First period start date'),
                subtitle: Text(
                  store.startDate == null
                      ? 'Tap to set (e.g. payday)'
                      : '${PayScheduleConfig.monthName(store.startDate!.month)} '
                          '${store.startDate!.day}, ${store.startDate!.year}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                onTap: () async {
                  final now = DateTime.now();
                  final initial = store.startDate ?? now;
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: initial,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    store.startDate = DateTime(
                      picked.year,
                      picked.month,
                      picked.day,
                    );
                  }
                },
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.timelapse_rounded,
                    color: AppTheme.primary,
                    size: 22,
                  ),
                ),
                title: const Text('Interval'),
                subtitle: const Text(
                  'Each period is exactly this many days (e.g. 14 = 2 weeks).',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_rounded),
                      onPressed: store.periodLengthDays > 7
                          ? () => store.periodLengthDays =
                              store.periodLengthDays - 1
                          : null,
                    ),
                    Text(
                      '${store.periodLengthDays} days',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_rounded),
                      onPressed: store.periodLengthDays < 31
                          ? () => store.periodLengthDays =
                              store.periodLengthDays + 1
                          : null,
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.calendar_month_rounded,
                  color: AppTheme.primary,
                  size: 22,
                ),
                title: Text(
                  'Example (${PayScheduleConfig.monthName(sampleMonth)} $sampleYear)',
                ),
                subtitle: Text(
                  'P1: ${config.period1DateRange(sampleYear, sampleMonth)}  ·  '
                  'P2: ${config.period2DateRange(sampleYear, sampleMonth)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          _SettingsSection(
            title: 'Month reporting',
            children: [
              const ListTile(
                title: Text('When viewing by month'),
                subtitle: Text(
                  'Which pay periods count toward a calendar month, and how amounts are included.',
                  style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant),
                ),
              ),
              ...MonthInclusionPolicy.values.map((policy) {
                return RadioListTile<MonthInclusionPolicy>(
                  value: policy,
                  groupValue: store.monthInclusionPolicy,
                  onChanged: (v) {
                    if (v != null) store.monthInclusionPolicy = v;
                  },
                  title: Text(
                    policy == MonthInclusionPolicy.startMonth
                        ? 'By period start'
                        : policy == MonthInclusionPolicy.endMonth
                            ? 'By period end (payroll at close)'
                            : 'Accrual (prorate by day overlap)',
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    policy == MonthInclusionPolicy.startMonth
                        ? 'Include period in the month of its start date.'
                        : policy == MonthInclusionPolicy.endMonth
                            ? 'Include period in the month of its end date.'
                            : 'Include overlapping periods; prorate amounts by days in that month.',
                    style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Card(
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

