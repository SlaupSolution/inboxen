import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class DeliveryHistoryPage extends StatefulWidget {
  const DeliveryHistoryPage({super.key});

  @override
  State<DeliveryHistoryPage> createState() => _DeliveryHistoryPageState();
}

class _DeliveryHistoryPageState extends State<DeliveryHistoryPage> {
  List<Map<String, dynamic>> _completedDeliveries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCompletedDeliveries();
  }

  Future<void> _loadCompletedDeliveries() async {
    try {
      final data = await supabase
          .from('orders')
          .select('*, profiles:user_id(*)')
          .eq('status', 'completed')
          .order('created_at', ascending: false);

      setState(() {
        _completedDeliveries = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (error) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar histórico de entregas'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Histórico de Entregas'),
        backgroundColor: Colors.deepOrange,
        actions: [
          IconButton(
            icon: Icon(Icons.home),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/home');
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadCompletedDeliveries,
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _completedDeliveries.isEmpty
              ? Center(child: Text('Nenhuma entrega concluída'))
              : ListView.builder(
                  itemCount: _completedDeliveries.length,
                  itemBuilder: (context, index) {
                    final delivery = _completedDeliveries[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        title: Text('Pedido #${delivery['id']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Data: ${DateTime.parse(delivery['created_at']).toString().split('.')[0]}'),
                            Text(
                                'Entregador: ${delivery['profiles']['full_name'] ?? 'N/A'}'),
                            Text('Status: Concluído'),
                          ],
                        ),
                        trailing: Icon(Icons.check_circle, color: Colors.green),
                        onTap: () {
                          // Adicionar navegação para detalhes do pedido se necessário
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
