import 'package:flutter/material.dart';

class OrderDetailPage extends StatelessWidget {
  final int orderId;

  const OrderDetailPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sipariş #$orderId'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Edit order
            },
            tooltip: 'Düzenle',
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              // TODO: Print order
            },
            tooltip: 'Yazdır',
          ),
        ],
      ),
      body: const Center(
        child: Text('Sipariş detayı yükleniyor...'),
      ),
    );
  }
}
