// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:io';


import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:payment/order_list_screen.dart';
import 'package:payment/pay.dart';
import 'package:payment/utils.dart';

class CreateOrderScreen extends StatefulWidget {
  final Accounts account;
  final List<Product>? products;
  final Function onOrderCreated;

  const CreateOrderScreen({
    Key? key,
    required this.account,
    this.products,
    required this.onOrderCreated,
  }) : super(key: key);

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _clientNotesController = TextEditingController();
  final TextEditingController _utrController = TextEditingController();
  String? _invoiceImage;
  String? _transactionImage;
  String? _qrCodeData;
  String? _clientTxnId;
  Timer? _timer;
  int _secondsLeft = 120;
  bool _includeAmountInQr = false;
  late Accounts _account;
  List<Product>? _products;
  List<Product> _selectedProducts = [];
  final Map<Product, int> _selectedProductQuantities = {};

  @override
  void initState() {
    super.initState();
    _account = widget.account;
    _initializeProducts();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _amountController.dispose();
    _clientNotesController.dispose();
    _utrController.dispose();
    super.dispose();
  }

  Future<void> _initializeProducts() async {
    _products = await _fetchProductsFromDb(_account.productIds);

    setState(() {
      if (widget.products != null) {
        _selectedProducts = List.from(widget.products!);

        for (var product in _selectedProducts) {
          _selectedProductQuantities[product] = 1;
        }
      }

      _amountController.text = _calculateTotalAmount().toStringAsFixed(2);
    });
  }

  Future<List<Product>> _fetchProductsFromDb(List<int> productIds) async {
    var box = Hive.box<Product>('products');
    List<Product> products = [];

    for (int productId in productIds) {
      var product = box.get(productId);
      if (product != null) {
        products.add(product);
      }
    }

    return products;
  }

  double _calculateTotalAmount() {
    double totalAmount = 0.0;

    _selectedProductQuantities.forEach((product, quantity) {
      totalAmount += product.price * quantity;
    });

    return totalAmount;
  }

  void _generateQrCode() {
    if (_account.upiId.isEmpty || _account.merchantName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'UPI ID or Merchant Name is missing. Please configure it in accounts.'),
        ),
      );
      return;
    }

    setState(() {
      _clientTxnId = DateTime.now().millisecondsSinceEpoch.toString();

      // Conditionally include amount in QR data
      String qrData =
          'upi://pay?pa=${_account.upiId}&pn=${_account.merchantName}';
      if (_includeAmountInQr) {
        qrData += '&am=${_amountController.text}';
      }
      qrData += '&tn=$_clientTxnId&cu=${_account.currency}';

      _qrCodeData = qrData;
      _startTimer();
    });
  }

  void _startTimer() {
    _secondsLeft = 120;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft == 0) {
        _generateQrCode();
      } else {
        if (mounted) {
          setState(() {
            _secondsLeft--;
          });
        }
      }
    });
  }

  Future<void> _pickImage(bool isInvoice) async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (!mounted) return;

      if (pickedFile != null) {
        setState(() {
          if (isInvoice) {
            _invoiceImage = pickedFile.path;
          } else {
            _transactionImage = pickedFile.path;
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No image selected')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _saveQrCodeImage() async {
    try {
      final qrPainter = QrPainter(
        data: _qrCodeData!,
        version: QrVersions.auto,
        color: Colors.black,
        emptyColor: Colors.white,
      );
      final picData = await qrPainter.toImageData(200);

      if (picData != null) {
        final buffer = picData.buffer.asUint8List();
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/qr_code.png';
        final file = File(path);
        await file.writeAsBytes(buffer);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('QR Code saved to $path')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save QR Code: $e')),
      );
    }
  }

  Future<void> _uploadOrder() async {
    if (!mounted) return;

    if (_amountController.text.isEmpty ||
        _qrCodeData == null ||
        _invoiceImage == null ||
        _utrController.text.isEmpty ||
        _transactionImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all details')),
      );
      return;
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final qrPath = '${directory.path}/qr_code.png';
      final qrFile = File(qrPath);

      if (!qrFile.existsSync()) {
        await _saveQrCodeImage();
      }

      if (!qrFile.existsSync()) {
        throw Exception('QR Code file does not exist.');
      }

      final orderBox = Hive.box<Order>('orders');

      final Map<int, int> productsMap = {};
      _selectedProductQuantities.forEach((product, quantity) {
        productsMap[product.id] = quantity;
      });

      final order = Order(
        orderId: _clientTxnId!,
        amount: _amountController.text,
        clientNotes: _clientNotesController.text,
        qrCodeUrl: qrPath,
        invoiceImageUrl: _invoiceImage!,
        transactionImageUrl: _transactionImage!,
        utrNumber: _utrController.text,
        status: 'pending',
        timestamp: DateTime.now(),
        products: productsMap,
      );

      await orderBox.add(order);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order created successfully')),
      );

      _amountController.clear();
      _clientNotesController.clear();
      _utrController.clear();
      setState(() {
        _qrCodeData = null;
        _clientTxnId = null;
        _invoiceImage = null;
        _transactionImage = null;
        _selectedProducts.clear();
        _selectedProductQuantities.clear();
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const TransactionScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create order: $e')),
      );
    }
  }
void _showProductSelectionDialog() {
  TextEditingController searchController = TextEditingController();
  List<Product> filteredProducts =
      List.from(_products!); // Initialize filtered products

  showDialog(
    context: context,
    builder: (context) {
      // Using StatefulBuilder to manage the dialog's internal state
      return AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Select Products'),
            IconButton(
              icon: const Icon(Icons.add), // Add plus icon here
              onPressed: () {
                Navigator.of(context)
                    .pop(); // Close the current dialog before opening the new one
                _showAddProductForm(
                    context, _account); // Call the add product form
              },
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter dialogSetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Add Search Bar
                  TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      // Update the filtered products based on the search input
                      dialogSetState(() {
                        filteredProducts = _products!.where((product) {
                          return product.name
                              .toLowerCase()
                              .contains(value.toLowerCase());
                        }).toList();
                      });
                    },
                  ),
                  const SizedBox(height: 8.0),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        final isSelected =
                            _selectedProducts.contains(product);

                        return ListTile(
                          leading: SizedBox(
                            width: 40.0, // Adjust the width as needed
                            height: 40.0, // Adjust the height as needed
                            child:product.imageUrl.isNotEmpty? Image.file(
                              File(product.imageUrl),
                              fit: BoxFit.cover,
                            ):SizedBox(),
                          ),
                          title: Text(product.name),
                          subtitle: Text(
                              'Price: ₹${product.price.toStringAsFixed(2)}'),
                          trailing: Checkbox(
                            value: isSelected,
                            onChanged: (bool? value) {
                              dialogSetState(() {
                                if (value == true) {
                                  if (!_selectedProducts.contains(product)) {
                                    _selectedProducts.add(product);
                                    _selectedProductQuantities[product] = 1;
                                  }
                                } else {
                                  _selectedProducts.remove(product);
                                  _selectedProductQuantities.remove(product);
                                }
                              });

                              // Update parent state when product selection changes
                              setState(() {
                                _amountController.text =
                                    _calculateTotalAmount()
                                        .toStringAsFixed(2);
                                _generateQrCode(); // Add this line
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                // Update parent state when dialog closes
                _amountController.text =
                    _calculateTotalAmount().toStringAsFixed(2);
                _generateQrCode(); // Add this line
              });
              Navigator.of(context).pop();
            },
            child: const Text('Done'),
          ),
        ],
      );
    },
  );
}

  Widget _buildQRCodeWidget() {
    if (_qrCodeData != null) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: QrImageView(
            data: _qrCodeData!,
            version: QrVersions.auto,
            size: 200.0,
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
Widget _buildSelectedProductList() {
  if (_selectedProducts.isNotEmpty) {
    return SizedBox(
      height: 100.0, // Maintain height as required
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedProducts.length,
        itemBuilder: (context, index) {
          final product = _selectedProducts[index];
          final quantity = _selectedProductQuantities[product] ?? 1;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8.0), // Reduced margin
            child: Container(
              padding: const EdgeInsets.all(8.0), // Reduce padding even further
              child: Column(
                mainAxisSize: MainAxisSize.min, // Minimize extra space
                crossAxisAlignment: CrossAxisAlignment.start, // Align content to the start
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center, // Center-align within row
                    children: [
                      SizedBox(
                        height: 50.0, // Reduced height for the image
                        width: 50.0, // Reduced width for the image
                        child: product.imageUrl.isNotEmpty?Image.file(
                          File(product.imageUrl),
                          fit: BoxFit.cover,
                        ):SizedBox(),
                      ),
                      const SizedBox(width: 2.0), // Minimal gap
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start, // Align text to the start
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 10.0, // Reduced font size
                            ),
                          ),
                          Text(
                            '₹${product.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 10.0, // Smaller font size
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start, // Align buttons to start
                      children: [
                        IconButton(
                          iconSize: 14.0, // Further reduced icon size
                          padding: EdgeInsets.zero, // Remove padding around icon button
                          constraints: const BoxConstraints(), // Remove constraints to fit better
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            setState(() {
                              if (quantity > 1) {
                                _selectedProductQuantities[product] = quantity - 1;
                              } else {
                                _selectedProducts.remove(product);
                                _selectedProductQuantities.remove(product);
                              }
                              _amountController.text = _calculateTotalAmount().toStringAsFixed(2);
                              _generateQrCode();
                            });
                          },
                        ),
                        Text(
                          quantity.toString(),
                          style: const TextStyle(fontSize: 10.0), // Reduced font size
                        ),
                        IconButton(
                          iconSize: 14.0, // Further reduced icon size
                          padding: EdgeInsets.zero, // Remove padding around icon button
                          constraints: const BoxConstraints(), // Remove constraints to fit better
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              _selectedProductQuantities[product] = quantity + 1;
                              _amountController.text = _calculateTotalAmount().toStringAsFixed(2);
                              _generateQrCode();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Total: ₹${(product.price * quantity).toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 10.0), // Smaller font size
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  } else {
    return const Text('No products selected');
  }
}

  Widget _buildImagePicker(String? imagePath, bool isInvoice) {
    return GestureDetector(
      onTap: () => _pickImage(isInvoice),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[200],
        ),
        width: double.infinity,
        height: 150.0,
        child: imagePath == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image,
                      size: 50,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      isInvoice
                          ? 'Select Invoice Image'
                          : 'Select Transaction Image',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            : Image.file(File(imagePath), fit: BoxFit.cover),
      ),
    );
  }

  void _showAddProductForm(BuildContext context, Accounts accounts) {
    final TextEditingController productNameController = TextEditingController();
    final TextEditingController productDescriptionController =
        TextEditingController();
    final TextEditingController productPriceController =
        TextEditingController();

    File? pickedImageFile;

    Future<void> pickImage(StateSetter setState) async {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        // Use setState from StatefulBuilder to update the image
        setState(() {
          pickedImageFile = File(pickedFile.path);
        });
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Add New Product'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: productNameController,
                      decoration:
                          const InputDecoration(hintText: 'Enter product name'),
                      autofocus: true,
                    ),
                    const SizedBox(height: 8.0),
                    TextField(
                      controller: productDescriptionController,
                      decoration: const InputDecoration(
                          hintText: 'Enter product description'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 8.0),
                    TextField(
                      controller: productPriceController,
                      decoration: const InputDecoration(
                          hintText: 'Enter product price'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8.0),
                    GestureDetector(
                      onTap: () => pickImage(setState),
                      child: pickedImageFile != null 
                          ? Image.file(
                              pickedImageFile!,
                              height: 150,
                              width: 150,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              height: 50,
                              width: 50,
                              color: Colors.grey[300],
                              child: const Icon(Icons.add_a_photo,
                                  color: Colors.white),
                            ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    final productName = productNameController.text.trim();
                    final productDescription =
                        productDescriptionController.text.trim();
                    final productPrice =
                        double.tryParse(productPriceController.text.trim()) ??
                            0.0;

                    if (productName.isNotEmpty) {
                      // Generate a unique ID by using the next available integer key
                      final productBox = Hive.box<Product>('products');
                      final int newProductId = productBox.isEmpty
                          ? 0
                          : productBox.keys.cast<int>().last + 1;

                      // Create the new product
                      final newProduct = Product(
                        id: newProductId,
                        name: productName,
                        price: productPrice,
                        description: productDescription,
                        imageUrl: pickedImageFile!
                            .path, // Store the file path if an image is picked
                      );

                      // Save the product to the Hive box
                      productBox.put(newProductId, newProduct);

                      // Update the accounts with the new product ID
                      accounts.productIds.add(newProductId);
                      Hive.box<Accounts>('accounts')
                          .put(accounts.key, accounts);

                      Navigator.of(context).pop();
                      widget.onOrderCreated();
                      _selectedProducts.add(newProduct);
                      _generateQrCode();
                    }

                    _refresh();
                  },
                  child: const Text('Save'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _refresh() {
    setState(() {
      _initializeProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Order'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              orderCard(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Products:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _showProductSelectionDialog,
                  ),
                ],
              ),
              _buildSelectedProductList(),
              const SizedBox(height: 16.0),
              TextField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Total Amount',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _clientNotesController,
                decoration: const InputDecoration(
                  labelText: 'Client Notes',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              _buildQRCodeWidget(),
              const SizedBox(height: 16.0),

              // Checkbox for including amount in QR
              Row(
                children: [
                  Checkbox(
                    value: _includeAmountInQr,
                    onChanged: (bool? value) {
                      setState(() {
                        _includeAmountInQr = value ?? false;
                        _generateQrCode();
                      });
                    },
                  ),
                  const Text('Include amount in QR'),
                ],
              ),

              // Row for image pickers
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: _buildImagePicker(_invoiceImage, true),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: _buildImagePicker(_transactionImage, false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _utrController,
                decoration: const InputDecoration(
                  labelText: 'UTR Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              // ElevatedButton(
              //   onPressed: _generateQrCode,
              //   child: const Text('Generate QR Code'),
              // ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _uploadOrder,
                child: const Text('Create Order'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Card orderCard() {
    // Format the UPI ID
    String formattedUpiId = formatUpiId(_account.upiId);

    // Get the initials for the avatar
    String initials = getInitials(_account.merchantName);

    // Choose a color for the avatar background
    Color avatarColor =
        Color(_account.color); // You can change this to any color you prefer

    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Avatar with initials
            CircleAvatar(
              backgroundColor: avatarColor,
              radius: 30,
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ), // Adjust the radius as needed
            ),
            const SizedBox(width: 16.0),
            // Merchant info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _account.merchantName,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8.0),
                  Text('UPI ID: $formattedUpiId'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
