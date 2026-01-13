import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/finance.dart';
import '../models/transaction.dart' as app_transaction;
import '../services/api_service.dart';
import 'auth_provider.dart';

// Провайдер для финансовой информации
final financeProvider = StateNotifierProvider<FinanceNotifier, AsyncValue<Finance?>>((ref) {
  return FinanceNotifier(ref);
});

class FinanceNotifier extends StateNotifier<AsyncValue<Finance?>> {
  final Ref ref;

  FinanceNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadFinance();
  }

  Future<void> loadFinance() async {
    try {
      state = const AsyncValue.loading();
      final user = ref.read(authProvider).user;
      if (user != null) {
        final finance = await ApiService.getFinance(user.id.toString());
        state = AsyncValue.data(finance);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    await loadFinance();
  }
}

// Провайдер для списка транзакций
final transactionsProvider = StateNotifierProvider<TransactionsNotifier, AsyncValue<List<app_transaction.Transaction>>>((ref) {
  return TransactionsNotifier(ref);
});

class TransactionsNotifier extends StateNotifier<AsyncValue<List<app_transaction.Transaction>>> {
  final Ref ref;

  TransactionsNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    try {
      state = const AsyncValue.loading();
      final user = ref.read(authProvider).user;
      if (user != null) {
        final data = await ApiService.getTransactions(user.id.toString());
        final transactions = data.map((json) => app_transaction.Transaction.fromJson(json)).toList();
        state = AsyncValue.data(transactions);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    await loadTransactions();
  }

  Future<void> addTransaction(Map<String, dynamic> transactionData) async {
    try {
      final user = ref.read(authProvider).user;
      if (user != null) {
        await ApiService.createTransaction(user.id.toString(), transactionData);
        await loadTransactions();
        // Обновляем финансовую информацию
        await ref.read(financeProvider.notifier).refresh();
      }
    } catch (e) {
      rethrow;
    }
  }
}

