import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/account_store.dart';
import '../data/allocation_store.dart';
import '../data/budget_store.dart';
import '../data/category_store.dart';
import '../data/debt_store.dart';
import '../data/expense_store.dart';
import '../data/income_store.dart';
import '../data/pay_schedule_store.dart';
import '../data/transaction_store.dart';

/// Reloads all app data from local storage. Call from pull-to-refresh.
Future<void> reloadAllStores(BuildContext context) async {
  await Future.wait([
    context.read<AccountStore>().reload(),
    context.read<AllocationStore>().reload(),
    context.read<BudgetStore>().reload(),
    context.read<CategoryStore>().reload(),
    context.read<DebtStore>().reload(),
    context.read<ExpenseStore>().reload(),
    context.read<IncomeStore>().reload(),
    context.read<PayScheduleStore>().reload(),
    context.read<TransactionStore>().reload(),
  ]);
}
