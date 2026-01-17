import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/user_balance.dart';
import '../models/transaction.dart';

// State для баланса
class BalanceState {
  final UserBalance? balance;
  final bool isLoading;
  final String? error;

  BalanceState({
    this.balance,
    this.isLoading = false,
    this.error,
  });

  BalanceState copyWith({
    UserBalance? balance,
    bool? isLoading,
    String? error,
  }) {
    return BalanceState(
      balance: balance ?? this.balance,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Notifier для баланса
class BalanceNotifier extends StateNotifier<BalanceState> {
  BalanceNotifier() : super(BalanceState()) {
    loadBalance();
  }

  Future<void> loadBalance() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await ApiService.getUserBalance();
      final balance = UserBalance.fromJson(data);
      state = state.copyWith(balance: balance, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    await loadBalance();
  }
}

// State для транзакций
class TransactionsState {
  final List<TransactionModel> transactions;
  final bool isLoading;
  final String? error;
  final int total;

  TransactionsState({
    this.transactions = const [],
    this.isLoading = false,
    this.error,
    this.total = 0,
  });

  TransactionsState copyWith({
    List<TransactionModel>? transactions,
    bool? isLoading,
    String? error,
    int? total,
  }) {
    return TransactionsState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      total: total ?? this.total,
    );
  }
}

// Notifier для транзакций
class TransactionsNotifier extends StateNotifier<TransactionsState> {
  TransactionsNotifier() : super(TransactionsState()) {
    loadTransactions();
  }

  Future<void> loadTransactions({String? type, String? status}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await ApiService.getUserTransactions(type: type, status: status);
      final transactions = (data['transactions'] as List)
          .map((json) => TransactionModel.fromJson(json))
          .toList();
      state = state.copyWith(
        transactions: transactions,
        total: data['total'] ?? 0,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    await loadTransactions();
  }
}

// Providers
final balanceProvider = StateNotifierProvider<BalanceNotifier, BalanceState>((ref) {
  return BalanceNotifier();
});

final transactionsProvider = StateNotifierProvider<TransactionsNotifier, TransactionsState>((ref) {
  return TransactionsNotifier();
});
