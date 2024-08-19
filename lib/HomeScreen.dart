import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hive/hive.dart';
import 'pay.dart'; // Assuming your Hive models are in pay.dart

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  Box<Order>? orderBox;
  List<Order> orders = [];
  String? selectedAccount;
  String selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    _openBox();
  }

  Future<void> _openBox() async {
    try {
      orderBox = await Hive.openBox<Order>('orders');
      setState(() {
        orders = orderBox!.values.toList();
      });
    } catch (error) {
      print('Error opening Hive box: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Transactions'),
      ),
      body: orderBox == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildFilters(),
          Expanded(
            child: orders.isEmpty
                ? const Center(child: Text('No transactions available'))
                : ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                if (selectedStatus != 'All' && order.status != selectedStatus) {
                  return SizedBox.shrink();
                }
                return _buildOrderCard(order);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          DropdownButton<String>(
            value: selectedStatus,
            items: <String>['All', 'Pending', 'Completed'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                selectedStatus = newValue!;
              });
            },
          ),
          // Add account filter if needed
          // DropdownButton<String>(
          //   value: selectedAccount,
          //   items: <String>['Account1', 'Account2'].map((String value) {
          //     return DropdownMenuItem<String>(
          //       value: value,
          //       child: Text(value),
          //     );
          //   }).toList(),
          //   onChanged: (String? newValue) {
          //     setState(() {
          //       selectedAccount = newValue;
          //     });
          //   },
          // ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order ID: ${order.orderId}', style: Theme.of(context).textTheme.titleLarge),
            Text('Amount: ${order.amount}', style: Theme.of(context).textTheme.bodyLarge),
            Text('Status: ${order.status}', style: Theme.of(context).textTheme.bodyLarge),
            Text('UTR Number: ${order.utrNumber}', style: Theme.of(context).textTheme.bodyLarge),
            Text('Client Notes: ${order.clientNotes}', style: Theme.of(context).textTheme.bodyLarge),
            SizedBox(height: 8),
            Text('Invoice Image:', style: Theme.of(context).textTheme.bodyLarge),
            _buildImageWidget(order.invoiceImageUrl, () async {
              final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
              if (pickedFile != null) {
                setState(() {
                  order.invoiceImageUrl = pickedFile.path;
                  order.save();
                });
              }
            }),
            SizedBox(height: 8),
            Text('Transaction Image:', style: Theme.of(context).textTheme.bodyLarge),
            _buildImageWidget(order.transactionImageUrl, () async {
              final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
              if (pickedFile != null) {
                setState(() {
                  order.transactionImageUrl = pickedFile.path;
                  order.save();
                });
              }
            }),
            SizedBox(height: 8),
            Text('Timestamp: ${order.timestamp}', style: Theme.of(context).textTheme.bodyLarge),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                _editOrder(order);
              },
              child: Text('Edit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(String? imagePath, Function onTap) {
    return GestureDetector(
      onTap: () => onTap(),
      child: imagePath == null || imagePath.isEmpty
          ? Container(
        width: 100,
        height: 100,
        color: Colors.grey[300],
        child: Icon(Icons.image, color: Colors.grey[700]),
      )
          : Image.file(File(imagePath), width: 100, height: 100),
    );
  }

  void _editOrder(Order order) {
    String newAmount = order.amount;
    String newStatus = order.status;
    String newUtrNumber = order.utrNumber;
    String newClientNotes = order.clientNotes;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit Order'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      initialValue: order.amount,
                      decoration: InputDecoration(labelText: 'Amount'),
                      onChanged: (value) => newAmount = value,
                    ),
                    DropdownButton<String>(
                      value: newStatus,
                      items: <String>['Pending', 'Completed'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          newStatus = newValue!;
                        });
                      },
                    ),
                    TextFormField(
                      initialValue: order.utrNumber,
                      decoration: InputDecoration(labelText: 'UTR Number'),
                      onChanged: (value) => newUtrNumber = value,
                    ),
                    TextFormField(
                      initialValue: order.clientNotes,
                      decoration: InputDecoration(labelText: 'Client Notes'),
                      onChanged: (value) => newClientNotes = value,
                    ),
                    SizedBox(height: 16),
                    Text('Invoice Image:'),
                    SizedBox(height: 8),
                    _buildImageWidget(order.invoiceImageUrl, () async {
                      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                      if (pickedFile != null) {
                        setState(() {
                          order.invoiceImageUrl = pickedFile.path;
                        });
                      }
                    }),
                    SizedBox(height: 16),
                    Text('Transaction Image:'),
                    SizedBox(height: 8),
                    _buildImageWidget(order.transactionImageUrl, () async {
                      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                      if (pickedFile != null) {
                        setState(() {
                          order.transactionImageUrl = pickedFile.path;
                        });
                      }
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    await _updateOrder(
                      order,
                      newAmount,
                      newStatus,
                      newUtrNumber,
                      newClientNotes,
                    );
                    Navigator.of(context).pop();
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateOrder(
      Order order,
      String newAmount,
      String newStatus,
      String newUtrNumber,
      String newClientNotes,
      ) async {
    // Update text fields
    order.amount = newAmount;
    order.status = newStatus;
    order.utrNumber = newUtrNumber;
    order.clientNotes = newClientNotes;

    // Save the updated order back to Hive
    await order.save();

    // Refresh UI
    setState(() {});
  }
}
