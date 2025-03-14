import 'package:flutter/material.dart';
import '../services/order_service.dart';
import '../services/notification_service.dart';
import '../services/location_service.dart';
import '../widgets/delivery_map.dart';
import 'chat_page.dart';
import 'package:geolocator/geolocator.dart';

class OrderDetailsPage extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailsPage({
    super.key,
    required this.order,
  });

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  final _orderService = OrderService();
  final _notificationService = NotificationService();
  final _locationService = LocationService();
  bool _isLoading = false;
  Position? _pickupLocation;
  Position? _deliveryLocation;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    final pickup = await _locationService.getCoordinatesFromAddress(
      widget.order['pickup_address'],
    );
    final delivery = await _locationService.getCoordinatesFromAddress(
      widget.order['delivery_address'],
    );

    setState(() {
      _pickupLocation = pickup;
      _deliveryLocation = delivery;
    });
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _isLoading = true);

    try {
      final success = await _orderService.updateOrderStatus(
        orderId: widget.order['id'],
        status: status,
        context: context,
      );

      if (success) {
        await _notificationService.showOrderStatusNotification(
          orderId: widget.order['id'],
          title: 'Status da Entrega Atualizado',
          body: 'A entrega #${widget.order['id']} foi atualizada para: $status',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDeliverer = widget.order['delivery_user_id'] != null;
    final height = MediaQuery.of(context).size.height;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Entrega #${widget.order['id']}'),
        backgroundColor: Colors.deepOrange,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  if (_pickupLocation != null)
                    SizedBox(
                      height: height * 0.4,
                      child: DeliveryMap(
                        orderId: widget.order['id'],
                        initialPosition: _pickupLocation,
                        destinationPosition: _deliveryLocation,
                        trackDelivery: widget.order['status'] == 'in_progress',
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusCard(),
                        SizedBox(height: 16),
                        _buildAddressCard(),
                        SizedBox(height: 16),
                        _buildPriceCard(),
                        SizedBox(height: 16),
                        _buildDescriptionCard(),
                        if (widget.order['status'] == 'pending')
                          _buildActionButton(),
                        if (isDeliverer && widget.order['status'] == 'in_progress')
                          _buildCompleteButton(),
                        SizedBox(height: 16),
                        _buildChatButton(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getStatusText(),
                style: TextStyle(
                  color: _getStatusColor(),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Endereços',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            ListTile(
              leading: Icon(Icons.location_on, color: Colors.deepOrange),
              title: Text('Coleta'),
              subtitle: Text(widget.order['pickup_address']),
            ),
            ListTile(
              leading: Icon(Icons.local_shipping, color: Colors.deepOrange),
              title: Text('Entrega'),
              subtitle: Text(widget.order['delivery_address']),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Valor',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'R\$ ${widget.order['price'].toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 24,
                color: Colors.deepOrange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Descrição',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(widget.order['description'] ?? 'Sem descrição'),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading
            ? null
            : () async {
                await _orderService.acceptOrder(
                  orderId: widget.order['id'],
                  context: context,
                );
                Navigator.pop(context);
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepOrange,
          padding: EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text('Aceitar Entrega'),
      ),
    );
  }

  Widget _buildCompleteButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading
            ? null
            : () async {
                await _orderService.completeOrder(
                  orderId: widget.order['id'],
                  context: context,
                );
                Navigator.pop(context);
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text('Concluir Entrega'),
      ),
    );
  }

  Widget _buildChatButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatPage(orderId: widget.order['id']),
            ),
          );
        },
        icon: Icon(Icons.chat),
        label: Text('Chat da Entrega'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.deepOrange,
          side: BorderSide(color: Colors.deepOrange),
          padding: EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (widget.order['status']) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (widget.order['status']) {
      case 'pending':
        return 'Pendente';
      case 'in_progress':
        return 'Em Andamento';
      case 'completed':
        return 'Concluída';
      case 'cancelled':
        return 'Cancelada';
      default:
        return 'Desconhecido';
    }
  }
}