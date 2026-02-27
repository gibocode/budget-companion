/// Amount to allocate to an account for a given pay period. Source of truth: [periodKey] (yyyy-mm-dd of period start).
class AccountAllocation {
  const AccountAllocation({
    required this.accountId,
    required this.periodKey,
    required this.amount,
  });

  final String accountId;
  /// Stable key for the pay period (yyyy-mm-dd of period start). Derives from pay schedule anchor + 14-day sequence.
  final String periodKey;
  final double amount;

  AccountAllocation copyWith({
    String? accountId,
    String? periodKey,
    double? amount,
  }) {
    return AccountAllocation(
      accountId: accountId ?? this.accountId,
      periodKey: periodKey ?? this.periodKey,
      amount: amount ?? this.amount,
    );
  }
}
