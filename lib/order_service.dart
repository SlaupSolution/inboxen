import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart';
import 'notification_service.dart';

class OrderService {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  final _notificationService = NotificationService();

  Future<bool> createOrder({
    required String pickupAddress,
    required String deliveryAddress,
    required double price,
    required String description,
    required BuildContext context,
  }) async {
    try {
      final response = await supabase.from('orders').insert({
        'user_id': supabase.auth.currentUser!.id,
        'pickup_address': pickupAddress,
        'delivery_address': deliveryAddress,
        'price': price,
        'description': description,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      }).select();

      if (response.isNotEmpty) {
        final order = response.first;
        await _notificationService.showNewOrderNotification(
          title: 'Nova Entrega Disponível',
          body: 'Nova entrega de R\$ ${price.toStringAsFixed(2)}',
          orderId: order['id'],
        );
        return true;
      }
      return false;
    } on PostgrestException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar entrega: ${error.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  Future<bool> acceptOrder({
    required int orderId,
    required BuildContext context,
  }) async {
    try {
      await supabase.from('orders').update({
        'delivery_user_id': supabase.auth.currentUser!.id,
        'status': 'in_progress',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      await _notificationService.showOrderStatusNotification(
        title: 'Entrega Aceita',
        body: 'A entrega #$orderId foi aceita e está em andamento',
        orderId: orderId,
      );

      return true;
    } on PostgrestException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao aceitar entrega: ${error.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  Future<bool> completeOrder({
    required int orderId,
    required BuildContext context,
  }) async {
    try {
      await supabase.from('orders').update({
        'status': 'completed',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      await _notificationService.showOrderStatusNotification(
        title: 'Entrega Concluída',
        body: 'A entrega #$orderId foi concluída com sucesso!',
        orderId: orderId,
      );

      return true;
    } on PostgrestException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao concluir entrega: ${error.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  Future<bool> cancelOrder({
    required int orderId,
    required BuildContext context,
  }) async {
    try {
      await supabase.from('orders').update({
        'status': 'cancelled',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      await _notificationService.showOrderStatusNotification(
        title: 'Entrega Cancelada',
        body: 'A entrega #$orderId foi cancelada',
        orderId: orderId,
      );

      return true;
    } on PostgrestException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao cancelar entrega: ${error.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getOrders({
    String? status,
    bool? isDeliverer,
  }) async {
    try {
      final query = supabase
          .from('orders')
          .select('*, profiles:user_id(*)');

      if (status != null) {
        query.eq('status', status);
      }

      if (isDeliverer == true) {
        query.eq('delivery_user_id', supabase.auth.currentUser!.id);
      } else if (isDeliverer == false) {
        query.eq('user_id', supabase.auth.currentUser!.id);
      }

      query.order('created_at', ascending: false);

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching orders: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getOrderDetails(int orderId) async {
    try {
      final response = await supabase
          .from('orders')
          .select('*, profiles:user_id(*), delivery_profile:delivery_user_id(*)')
          .eq('id', orderId)
          .single();
      
      return response;
    } catch (e) {
      print('Error fetching order details: $e');
      return null;
    }
  }

  Stream<List<Map<String, dynamic>>> watchOrders({String? status}) {
    return supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('status', status ?? 'pending')
        .order('created_at')
        .map((events) => List<Map<String, dynamic>>.from(events));
  }
}