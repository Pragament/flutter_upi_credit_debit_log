import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:payment/order_detail_screen.dart';
import 'package:payment/pay.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _TransactionScreenState createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  String _selectedStatus = 'all'; // Default to 'all'
  String _searchQuery = ''; // Default to empty search query

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Transactions'),
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Search Bar
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase(); // Update search query
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'Search by product...',
                      hintStyle: TextStyle(color: Colors.black54),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Status Filter Dropdown
                DropdownButton<String>(
                  value: _selectedStatus,
                  items: <String>['all', 'pending', 'completed'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedStatus = newValue ?? 'all';
                    });
                  },
                  icon: const Icon(Icons.filter_list),
                ),
              ],
            ),
          ),
          // Orders List
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: Hive.box<Order>('orders').listenable(),
              builder: (context, Box<Order> box, _) {
                final productBox = Hive.box<Product>('products');
                
                final orders = box.values.where((order) {
                  final matchesStatus = _selectedStatus == 'all' || order.status == _selectedStatus;
                  
                  // Check if any product in the order matches the search query
                  final matchesSearch = _searchQuery.isEmpty || order.products.keys.any((productId) {
                    final product = productBox.get(productId);
                    return product != null && product.name.toLowerCase().contains(_searchQuery);
                  });

                  return matchesStatus && matchesSearch;
                }).toList();

                if (orders.isEmpty) {
                  return const Center(
                    child: Text('No transactions available.'),
                  );
                }

                return ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return OrderCard(order: order);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
class OrderCard extends StatelessWidget {
  final Order order;

  const OrderCard({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formattedTimestamp =
        DateFormat('d MMMM yyyy, h:mma').format(order.timestamp);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailsScreen(order: order),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.all(8.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ProductImagesList(productIds: order.products.keys.toList()),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      _showEditDialog(context, order);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Order ${order.status}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Placed at: $formattedTimestamp',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        const WidgetSpan(
                          child: Icon(Icons.currency_rupee, size: 16),
                        ),
                        TextSpan(
                          text: ' ${order.amount}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, Order order) {
    final amountController = TextEditingController(text: order.amount);
    String? selectedStatus = order.status;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Order'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                items: <String>['pending', 'completed'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  selectedStatus = newValue;
                },
                decoration: const InputDecoration(
                  labelText: 'Status',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Update the order with new data
                if (selectedStatus != null) {
                  order.status = selectedStatus!;
                  order.amount = amountController.text;
                  order.save(); // Save changes to the Hive database
                }

                Navigator.pop(context);
              },
              child: const Text('Save Changes'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
class ProductImagesList extends StatelessWidget {
  final List<int> productIds;

  const ProductImagesList({Key? key, required this.productIds})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final productBox = Hive.box<Product>('products');

    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: productIds.length,
        itemBuilder: (context, index) {
          final product = productBox.get(productIds[index]);

          return product != null
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: [
                      Image.file(
                        File(product.imageUrl),
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ],
                  ),
                )
              : const SizedBox();
        },
      ),
    );
  }
}
