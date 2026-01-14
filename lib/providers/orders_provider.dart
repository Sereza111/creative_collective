import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';
import '../models/order_application.dart';
import '../services/api_service.dart';

class OrdersState {
  final List<Order> orders;
  final bool isLoading;
  final String? error;

  OrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
  });

  OrdersState copyWith({
    List<Order>? orders,
    bool? isLoading,
    String? error,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class OrdersNotifier extends StateNotifier<OrdersState> {
  OrdersNotifier() : super(OrdersState()) {
    loadOrders();
  }

  Future<void> loadOrders({String? status, String? category}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final orders = await ApiService.getOrders(status: status, category: category);
      state = state.copyWith(orders: orders, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> createOrder(Map<String, dynamic> orderData) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final newOrder = await ApiService.createOrder(orderData);
      state = state.copyWith(
        orders: [newOrder, ...state.orders],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }

  Future<void> updateOrder(int orderId, Map<String, dynamic> orderData) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updatedOrder = await ApiService.updateOrder(orderId, orderData);
      state = state.copyWith(
        orders: state.orders.map((order) => order.id == orderId ? updatedOrder : order).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }

  Future<void> deleteOrder(int orderId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ApiService.deleteOrder(orderId);
      state = state.copyWith(
        orders: state.orders.where((order) => order.id != orderId).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }

  Future<void> applyToOrder(int orderId, Map<String, dynamic> applicationData) async {
    try {
      await ApiService.applyToOrder(orderId, applicationData);
      // Обновляем список заказов после отклика
      await loadOrders();
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final ordersProvider = StateNotifierProvider<OrdersNotifier, OrdersState>((ref) {
  return OrdersNotifier();
});

