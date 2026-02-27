import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Simple SQLite database helper.
///
/// For now we only persist categories, but this can be extended
/// to support other entities (expenses, accounts, etc.) later.
class LocalDb {
  LocalDb._internal();

  static final LocalDb instance = LocalDb._internal();

  Database? _db;

  Future<Database> get database async {
    final existing = _db;
    if (existing != null) return existing;
    final db = await _open();
    _db = db;
    return db;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'budget_companion.db');

    return openDatabase(
      path,
      version: 15,
      onCreate: (db, version) async {
        await _createSchema(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 1) {
          await _createSchema(db);
        }
        if (oldVersion < 2) {
          await _createPayScheduleTable(db);
        }
        if (oldVersion < 3) {
          await _createBudgetsTable(db);
        }
        if (oldVersion < 4) {
          await db.execute(
            'ALTER TABLE budgets ADD COLUMN name TEXT',
          );
        }
        if (oldVersion < 5) {
          await db.execute(
            'ALTER TABLE budgets ADD COLUMN period_key TEXT',
          );
        }
        if (oldVersion < 6) {
          await db.execute(
            'ALTER TABLE pay_schedule ADD COLUMN month_inclusion_policy INTEGER NOT NULL DEFAULT 0',
          );
        }
        if (oldVersion < 7) {
          await _createAccountsTable(db);
          await _createAccountAllocationsTable(db);
        }
        if (oldVersion < 8) {
          await db.execute(
            'ALTER TABLE budgets ADD COLUMN account_id TEXT',
          );
        }
        if (oldVersion < 9) {
          await db.execute(
            'ALTER TABLE accounts ADD COLUMN account_type INTEGER NOT NULL DEFAULT 1',
          );
        }
        if (oldVersion < 10) {
          await db.execute(
            'ALTER TABLE budgets ADD COLUMN recurrence_interval INTEGER NOT NULL DEFAULT 1',
          );
          await db.execute(
            'ALTER TABLE budgets ADD COLUMN recurrence_max_count INTEGER',
          );
        }
        if (oldVersion < 11) {
          await _createExpensesTable(db);
          await _createTransactionsTable(db);
          await _createIncomesTable(db);
          await _createIncomeRecordsTable(db);
        }
        if (oldVersion < 12) {
          await db.execute(
            'ALTER TABLE accounts ADD COLUMN amount REAL NOT NULL DEFAULT 0',
          );
        }
        if (oldVersion < 13) {
          await _createDebtsTable(db);
        }
        if (oldVersion < 14) {
          await db.execute(
            'ALTER TABLE debts ADD COLUMN category_id TEXT',
          );
        }
        if (oldVersion < 15) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS debts_new (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              category_id TEXT,
              monthly_amount REAL NOT NULL,
              months_remaining INTEGER NOT NULL,
              next_due_date TEXT NOT NULL
            )
          ''');
          await db.execute('''
            INSERT INTO debts_new (id, name, category_id, monthly_amount, months_remaining, next_due_date)
            SELECT id, name, category_id, monthly_amount, months_remaining, next_due_date FROM debts
          ''');
          await db.execute('DROP TABLE debts');
          await db.execute('ALTER TABLE debts_new RENAME TO debts');
        }
      },
    );
  }

  Future<void> _createSchema(Database db) async {
    // Categories table mirrors the Category model.
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        sort_order INTEGER NOT NULL,
        icon_code_point INTEGER NOT NULL,
        color_value INTEGER NOT NULL,
        type INTEGER NOT NULL,
        parent_id TEXT
      )
    ''');

    await _createPayScheduleTable(db);
    await _createBudgetsTable(db);
    await _createAccountsTable(db);
    await _createAccountAllocationsTable(db);
    await _createExpensesTable(db);
    await _createTransactionsTable(db);
    await _createIncomesTable(db);
    await _createIncomeRecordsTable(db);
    await _createDebtsTable(db);
  }

  Future<void> _createExpensesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS expenses (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category_id TEXT NOT NULL,
        amount REAL NOT NULL,
        frequency INTEGER NOT NULL,
        schedule_type INTEGER NOT NULL,
        recurring_expected_amount REAL,
        due_date TEXT,
        budget_type INTEGER NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _createTransactionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        id TEXT PRIMARY KEY,
        type INTEGER NOT NULL,
        reference_id TEXT NOT NULL,
        date TEXT NOT NULL,
        amount REAL NOT NULL,
        notes TEXT,
        budget_id TEXT
      )
    ''');
  }

  Future<void> _createIncomesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS incomes (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category_id TEXT,
        recurring_expected_amount REAL,
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _createIncomeRecordsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS income_records (
        income_id TEXT NOT NULL,
        year INTEGER NOT NULL,
        month INTEGER NOT NULL,
        expected_amount REAL NOT NULL,
        actual_amount REAL NOT NULL,
        PRIMARY KEY (income_id, year, month)
      )
    ''');
  }

  Future<void> _createAccountsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        sort_order INTEGER NOT NULL,
        icon_color_value INTEGER,
        account_type INTEGER NOT NULL DEFAULT 1,
        amount REAL NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _createAccountAllocationsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS account_allocations (
        account_id TEXT NOT NULL,
        period_key TEXT NOT NULL,
        amount REAL NOT NULL,
        PRIMARY KEY (account_id, period_key),
        FOREIGN KEY (account_id) REFERENCES accounts(id)
      )
    ''');
  }

  Future<void> _createPayScheduleTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pay_schedule (
        id INTEGER PRIMARY KEY,
        start_date TEXT,
        period_length_days INTEGER NOT NULL,
        month_inclusion_policy INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _createBudgetsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS budgets (
        id TEXT PRIMARY KEY,
        type INTEGER NOT NULL,
        reference_id TEXT NOT NULL,
        year INTEGER NOT NULL,
        month INTEGER NOT NULL,
        pay_period_index INTEGER,
        expected_amount REAL NOT NULL,
        recurrence_mode INTEGER NOT NULL,
        copies_from_previous INTEGER NOT NULL,
        recurrence_interval INTEGER NOT NULL DEFAULT 1,
        recurrence_max_count INTEGER,
        name TEXT,
        period_key TEXT,
        account_id TEXT
      )
    ''');
  }

  Future<void> _createDebtsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS debts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category_id TEXT,
        monthly_amount REAL NOT NULL,
        months_remaining INTEGER NOT NULL,
        next_due_date TEXT NOT NULL
      )
    ''');
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('account_allocations');
    await db.delete('budgets');
    await db.delete('categories');
    await db.delete('accounts');
    await db.delete('pay_schedule');
    await db.delete('transactions');
    await db.delete('expenses');
    await db.delete('income_records');
    await db.delete('incomes');
    await db.delete('debts');
  }

  /// Closes the database and deletes the file. Next access will recreate
  /// an empty database with current schema. Caller should reload all stores.
  Future<void> resetDatabase() async {
    final existing = _db;
    _db = null;
    if (existing != null) {
      await existing.close();
    }
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'budget_companion.db');
    await deleteDatabase(path);
  }
}

