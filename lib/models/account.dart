/// Whether the account holds cash (physical) or is online (e.g. bank, e-wallet).
enum AccountType {
  cash,
  online,
}

extension AccountTypeX on AccountType {
  String get label => switch (this) {
        AccountType.cash => 'Cash',
        AccountType.online => 'Online',
      };
}

class Account {
  const Account({
    required this.id,
    required this.name,
    this.order = 0,
    this.iconColorValue,
    this.accountType = AccountType.online,
    this.amount = 0,
  });

  final String id;
  final String name;
  final int order;
  /// ARGB color value for the account icon (e.g. 0xFF2563EB). Null = use default by index.
  final int? iconColorValue;
  /// Cash (physical) or Online (bank, e-wallet).
  final AccountType accountType;
  /// Current balance / amount for this account.
  final double amount;

  Account copyWith({
    String? id,
    String? name,
    int? order,
    int? iconColorValue,
    AccountType? accountType,
    double? amount,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      order: order ?? this.order,
      iconColorValue: iconColorValue ?? this.iconColorValue,
      accountType: accountType ?? this.accountType,
      amount: amount ?? this.amount,
    );
  }
}
