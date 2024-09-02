import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import 'package:payment/order_detail_screen.dart';
import 'package:payment/pay.dart';
import 'package:table_calendar/table_calendar.dart';

class TransactionScreen extends StatefulWidget {
  final Accounts? account;

  const TransactionScreen({super.key, this.account});

  @override
  // ignore: library_private_types_in_public_api
  _TransactionScreenState createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  String _selectedStatus = 'all';
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;
  final LocalAuthentication auth = LocalAuthentication();

  Timer? _inactivityTimer;
  static const int _inactivityDuration = 10 * 60; // 10 minutes in seconds

  @override
  void initState() {
    super.initState();
    _startInactivityTimer();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }

  // Method to start the inactivity timer
  void _startInactivityTimer() {
    _inactivityTimer?.cancel(); // Cancel any existing timer
    _inactivityTimer = Timer(Duration(seconds: _inactivityDuration), () async {
      bool isAuthenticated = await authenticate();
      if (!isAuthenticated) {
        // Handle failed authentication (e.g., lock the screen or navigate to a login screen)
        print('Authentication failed after inactivity.');
      } else {
        print('User authenticated successfully after inactivity.');
      }
    });
  }

  // Reset the inactivity timer on user activity
  void _resetInactivityTimer() {
    _startInactivityTimer();
  }

  Future<bool> authenticate() async {
    try {
      bool canCheckBiometrics = await auth.canCheckBiometrics;
      bool isAuthenticated = false;

      if (canCheckBiometrics) {
        isAuthenticated = await auth.authenticate(
          localizedReason: 'Please authenticate to access the app',
          options: const AuthenticationOptions(biometricOnly: true),
        );
      } else {}

      return isAuthenticated;
    } catch (e) {
      return false;
    }
  }

  void _showDateRangePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        DateTime? tempStartDate = _startDate;
        DateTime? tempEndDate = _endDate;
        Map<DateTime, List<Order>> ordersPerDay = {};

        final orders = Hive.box<Order>('orders').values;
        print('Total orders in Hive box: ${orders.length}');
        for (var order in orders) {
          print('Order timestamp: ${order.timestamp}');
          final orderDate = DateTime(
              order.timestamp.year, order.timestamp.month, order.timestamp.day);
          print('Normalized order date: $orderDate');
          if (ordersPerDay.containsKey(orderDate)) {
            ordersPerDay[orderDate]!.add(order);
          } else {
            ordersPerDay[orderDate] = [order];
          }
        }

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TableCalendar(
                    focusedDay: DateTime.now(),
                    firstDay: DateTime(2000),
                    lastDay: DateTime(2100),
                    rangeSelectionMode: RangeSelectionMode.toggledOn,
                    selectedDayPredicate: (day) =>
                        isSameDay(day, tempStartDate) ||
                        isSameDay(day, tempEndDate),
                    rangeStartDay: tempStartDate,
                    rangeEndDay: tempEndDate,
                    onRangeSelected: (start, end, focusedDay) {
                      setModalState(() {
                        tempStartDate = start;
                        tempEndDate = end;
                      });
                    },
                    calendarStyle: const CalendarStyle(
                      outsideDaysVisible: false,
                    ),
                    eventLoader: (day) {
                      final normalizedDay =
                          DateTime(day.year, day.month, day.day);
                      return ordersPerDay[normalizedDay] ?? [];
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      setModalState(() {
                        if (tempStartDate == null ||
                            (tempStartDate != null && tempEndDate != null)) {
                          tempStartDate = selectedDay;
                          tempEndDate = null;
                        } else if (tempEndDate == null) {
                          tempEndDate = selectedDay;
                        }
                      });
                    },
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, day, events) {
                        if (events.isNotEmpty) {
                          return Positioned(
                            bottom: 0,
                            right: 2.0,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(6.0),
                              child: Center(
                                child: Text(
                                  '${events.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14.0,
                                  ),
                                ),
                              ),
                            ),
                          );
                        } else {
                          return const SizedBox();
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _startDate = tempStartDate;
                        _endDate = tempEndDate;
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Apply Date Filter'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: authenticate(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError || !snapshot.data!) {
          return const Scaffold(
            body: Center(child: Text('Authentication failed')),
          );
        } else {
          return customBody(context);
        }
      },
    );
  }

  Scaffold customBody(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Transactions'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: const InputDecoration(
                hintText: 'Search by product...',
                hintStyle: TextStyle(color: Colors.black54),
                border: OutlineInputBorder(),
              ),
            ),
          ),

          // Search, Filter, and Date Picker Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Search Bar

                const SizedBox(width: 16),
                // Status Filter Dropdown
                DropdownButton<String>(
                  value: _selectedStatus,
                  items: <String>['all', 'pending', 'completed']
                      .map((String value) {
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
                const SizedBox(width: 16),
                // Date Range Picker Button
                IconButton(
                  icon: const Icon(Icons.date_range),
                  onPressed: () {
                    _showDateRangePicker(context);
                  },
                ),
                if (_startDate != null && _endDate != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${DateFormat('d MMM, yy').format(_startDate!)} -'
                          '${DateFormat('d MMM, yy').format(_endDate!)}',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _startDate = null;
                              _endDate = null;
                            });
                          },
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Display Selected Date Range and Clear Button

          // Orders List
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: Hive.box<Order>('orders').listenable(),
              builder: (context, Box<Order> box, _) {
                final productBox = Hive.box<Product>('products');
                final orders = box.values.where((order) {
                  final matchesStatus = _selectedStatus == 'all' ||
                      order.status == _selectedStatus;

                  final matchesAccount = widget.account == null ||
                      order.products.keys.any((productId) {
                        return widget.account!.productIds.contains(productId);
                      });

                  final matchesSearch = _searchQuery.isEmpty ||
                      order.products.keys.any((productId) {
                        final product = productBox.get(productId);
                        return product != null &&
                            product.name.toLowerCase().contains(_searchQuery);
                      });

                  final matchesDate = (_startDate == null ||
                          order.timestamp.isAfter(_startDate!)) &&
                      (_endDate == null || order.timestamp.isBefore(_endDate!));

                  return matchesAccount &&
                      matchesStatus &&
                      matchesSearch &&
                      matchesDate;
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
                    child: ProductImagesList(
                        productIds: order.products.keys.toList()),
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
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                if (selectedStatus != null) {
                  order.status = selectedStatus!;
                  order.amount = amountController.text;
                  order.save();
                }

                Navigator.pop(context);
              },
              child: const Text('Save Changes'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
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
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: productIds.length,
        itemBuilder: (context, index) {
          final product = productBox.get(productIds[index]);

          return product != null
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.file(
                        File(product.imageUrl),
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                      Text(
                        product.name,
                        style: TextStyle(fontSize: 12),
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
