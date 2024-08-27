import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:payment/pay.dart';

class OrderDetailsScreen extends StatelessWidget {
  final Order order;

  const OrderDetailsScreen({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formattedTimestamp =
        DateFormat('d MMMM yyyy, h:mma').format(order.timestamp);
    final productBox = Hive.box<Product>('products');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and Item Count
            Text(
              'Status: ${order.status}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${order.products.length} items in order',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),

            // Product List
            Expanded(
              child: ListView.builder(
                itemCount: order.products.length,
                itemBuilder: (context, index) {
                  final productId = order.products.keys.toList()[index];
                  final product = productBox.get(productId);

                  return product != null
                      ? ListTile(
                          leading: Image.file(
                            File(product.imageUrl),
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                          title: Text(product.name),
                          subtitle: Text('Price: ₹${product.price}'),
                        )
                      : const SizedBox();
                },
              ),
            ),

            // Spacer to push total amount to the center
           

            // Total Amount
            Center(
              child: Text(
                'Total Amount: ₹${order.amount}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            const SizedBox(height: 16), // Add some space below the total amount
          ],
        ),
      ),
    );
  }
}
