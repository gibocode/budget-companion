import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'data/account_store.dart';
import 'data/allocation_store.dart';
import 'data/app_lock_store.dart';
import 'data/budget_store.dart';
import 'data/category_store.dart';
import 'data/expense_store.dart';
import 'data/debt_store.dart';
import 'data/income_store.dart';
import 'data/pay_schedule_store.dart';
import 'data/transaction_store.dart';
import 'theme/app_theme.dart';
import 'widgets/app_lock_gate.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppTheme.surfaceContainer,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const BudgetCompanionApp());
}

class BudgetCompanionApp extends StatelessWidget {
  const BudgetCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppLockStore()),
        ChangeNotifierProvider(create: (_) => IncomeStore()),
        ChangeNotifierProvider(create: (_) => AccountStore()),
        ChangeNotifierProvider(create: (_) => AllocationStore()),
        ChangeNotifierProvider(create: (_) => PayScheduleStore()),
        ChangeNotifierProvider(create: (_) => BudgetStore()),
        ChangeNotifierProvider(create: (_) => ExpenseStore()),
        ChangeNotifierProvider(create: (_) => CategoryStore()),
        ChangeNotifierProvider(create: (_) => TransactionStore()),
        ChangeNotifierProvider(create: (_) => DebtStore()),
      ],
      child: MaterialApp(
        title: 'Budget Companion',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AppLockGate(),
      ),
    );
  }
}
