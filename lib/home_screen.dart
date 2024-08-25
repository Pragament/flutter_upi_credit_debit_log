import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:payment/Create.dart';
import 'package:payment/product_list_screen.dart';
import 'package:payment/utils.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:payment/pay.dart';

class HomeScreen extends StatefulWidget {
  final QuickActions quickActions;

  const HomeScreen({Key? key, required this.quickActions}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Box<Accounts> accountsBox;
  late Box<Product> productBox;
  Color _selectedColor = Colors.blue;
  final TextEditingController _merchantNameController = TextEditingController();
  final TextEditingController _upiIdController = TextEditingController();
  final TextEditingController _currencyController = TextEditingController();
  bool _createShortcut = false;
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _searchQueryNotifier = ValueNotifier<String>('');

  @override
  void initState() {
    super.initState();
    accountsBox = Hive.box<Accounts>('accounts');
    productBox = Hive.box<Product>('products');
    _manageQuickActions(); // Initialize quick actions on startup
    _manageProductQuickActions(); // Initialize product quick actions
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchQueryNotifier.dispose();
    _merchantNameController.dispose();
    _upiIdController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _searchQueryNotifier.value = query;
  }

  List<Accounts> _filterAccounts(List<Accounts> accountsList, String query) {
    if (query.isEmpty) return accountsList;
    return accountsList.where((account) {
      return account.merchantName.toLowerCase().contains(query.toLowerCase()) ||
          account.upiId.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  void _showForm({Accounts? accounts}) {
    if (accounts != null) {
      _merchantNameController.text = accounts.merchantName;
      _upiIdController.text = accounts.upiId;
      _currencyController.text = accounts.currency;
      _selectedColor = Color(accounts.color);
      _createShortcut = accounts.createShortcut;
    } else {
      _merchantNameController.clear();
      _upiIdController.clear();
      _currencyController.clear();
      _selectedColor = Colors.blue;
      _createShortcut = false;
    }

    final bool isArchived = accounts?.archived ?? false;
    final DateTime? archiveDate = accounts?.archiveDate;
    final bool isDeletable = !isArchived ||
        (archiveDate != null &&
            DateTime.now().difference(archiveDate).inDays >= 30);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(accounts == null ? 'Add accounts' : 'Edit accounts'),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _merchantNameController,
                  decoration: const InputDecoration(labelText: 'Merchant Name'),
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: _upiIdController,
                  decoration: const InputDecoration(labelText: 'UPI ID'),
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: _currencyController,
                  decoration: const InputDecoration(labelText: 'Currency'),
                ),
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    const Text('Choose Color:'),
                    const SizedBox(width: 8.0),
                    GestureDetector(
                      onTap: _pickColor,
                      child: Container(
                        width: 30,
                        height: 30,
                        color: _selectedColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    Checkbox(
                      value: _createShortcut,
                      onChanged: (value) {
                        setState(() {
                          _createShortcut = value!;
                        });
                      },
                    ),
                    const Text('Create Shortcut'),
                  ],
                ),
                if (accounts != null) ...[
                  const SizedBox(height: 16.0),
                  Row(
                    children: [
                      Checkbox(
                        value: accounts.archived,
                        onChanged: (value) {
                          setState(() {
                            accounts.archived = value!;
                            accounts.archiveDate =
                                value ? DateTime.now() : null;
                          });
                        },
                      ),
                      const Text('Archived'),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          accounts != null
              ? TextButton(
                  onPressed: () {
                    if (!isDeletable) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'You cannot delete this account until 30 days have passed since archiving.'),
                        ),
                      );
                    } else {
                      _deleteaccounts(accounts);
                    }
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Delete',
                    style: TextStyle(
                      color: isDeletable ? Colors.red : Colors.grey,
                    ),
                  ),
                )
              : const SizedBox(
                  height: 0,
                  width: 0,
                ),
          TextButton(
            onPressed: () {
              if (accounts == null) {
                _addaccounts();
              } else {
                _updateaccounts(accounts);
              }
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _pickColor() async {
    final Color? color = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: _selectedColor,
            onColorChanged: (Color color) {
              setState(() => _selectedColor = color);
              Navigator.of(context).pop(color);
            },
          ),
        ),
      ),
    );

    if (color != null) {
      setState(() => _selectedColor = color);
    }
  }

  Future<void> _addaccounts() async {
    final id = accountsBox.isEmpty ? 0 : accountsBox.values.last.id + 1;
    final accounts = Accounts(
      id: id,
      merchantName: _merchantNameController.text,
      upiId: _upiIdController.text,
      currency: _currencyController.text,
      color: _selectedColor.value,
      createShortcut: _createShortcut,
      archived: false,
      productIds: [],
    );

    await accountsBox.put(id, accounts);
    if (_createShortcut) {
      _createQuickAction(accounts);
    }
    _manageQuickActions(); // Refresh the quick actions
    setState(() {});
  }

  Future<void> _updateaccounts(Accounts accounts) async {
    accounts.merchantName = _merchantNameController.text;
    accounts.upiId = _upiIdController.text;
    accounts.currency = _currencyController.text;
    accounts.color = _selectedColor.value;
    accounts.createShortcut = _createShortcut;

    if (accounts.archived == false) {
      accounts.archiveDate = null;
    } else if (accounts.archived) {
      accounts.archiveDate = DateTime.now();
    }

    await accounts.save();
    _manageQuickActions(); // Refresh the quick actions
    setState(() {});
  }

  Future<void> _deleteaccounts(Accounts accounts) async {
    await accounts.delete();
    _manageQuickActions(); // Refresh the quick actions
    setState(() {});
  }

  void _createQuickAction(Accounts accounts) {
    widget.quickActions.setShortcutItems(<ShortcutItem>[
      ShortcutItem(
        type: 'create_order_${accounts.id}',
        localizedTitle: 'Create Order for ${accounts.merchantName}',
        //icon: 'icon_add_order',
      ),
    ]);
  }

  void _manageQuickActions() {
    final shortcuts = Hive.box<Accounts>('accounts')
        .values
        .where((accounts) => accounts.createShortcut)
        .map((accounts) {
      return ShortcutItem(
        type: 'create_order_${accounts.id}',
        localizedTitle: 'Create Order for ${accounts.merchantName}',
      );
    }).toList();

    widget.quickActions.setShortcutItems(shortcuts);
  }

  void _manageProductQuickActions() {
    final products = Hive.box<Product>('products').values.toList();
    final shortcuts = products.map((product) {
      return ShortcutItem(
        type: 'view_product_${product.id}',
        localizedTitle: 'View Product ${product.name}',
      );
    }).toList();

    widget.quickActions.setShortcutItems(shortcuts);
  }

  void _showEditProductForm(BuildContext context, Product product,
      Accounts accounts, Function() refreshCallback) {
    final TextEditingController productNameController =
        TextEditingController(text: product.name);
    final TextEditingController productDescriptionController =
        TextEditingController(text: product.description);
    final TextEditingController productPriceController =
        TextEditingController(text: product.price.toString());

    File? pickedImageFile;
    bool createProdShortcut = product.createShortcut;
    bool isArchived = product.archived;
    DateTime? archiveDate = product.archiveDate;

    Future<void> pickImage(StateSetter setState) async {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        // Update the state using the setState from StatefulBuilder
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
              title: const Text('Edit Product'),
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
                          : product.imageUrl.isNotEmpty
                              ? Image.file(
                                  File(product.imageUrl),
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
                    const SizedBox(height: 16.0),
                    Row(
                      children: [
                        Checkbox(
                          value: createProdShortcut,
                          onChanged: (value) {
                            setState(() {
                              createProdShortcut = value!;
                            });
                          },
                        ),
                        const Text('Create Shortcut'),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      children: [
                        Checkbox(
                          value: isArchived,
                          onChanged: (value) {
                            setState(() {
                              isArchived = value!;
                              archiveDate = value ? DateTime.now() : null;
                            });
                          },
                        ),
                        const Text('Archived'),
                      ],
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
                      // Update the product details
                      product.name = productName;
                      product.description = productDescription;
                      product.price = productPrice;
                      if (pickedImageFile != null) {
                        product.imageUrl =
                            pickedImageFile!.path; // Store the file path
                      }
                      product.archived = isArchived;
                      product.archiveDate = archiveDate;

                      // Save the updated product
                      product.save();

                      // Manage the product shortcut creation
                      if (createProdShortcut) {
                        product.createShortcut = true;
                        _createProductQuickAction(product);
                        _manageProductQuickActions();
                      } else {
                        product.createShortcut = false;
                        _manageProductQuickActions();
                      }

                      refreshCallback(); // Trigger the refresh in the parent widget
                      Navigator.of(context).pop();
                    }
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

  void _createProductQuickAction(Product product) {
    const QuickActions quickActions = QuickActions();
    quickActions.setShortcutItems([
      ShortcutItem(
        type: 'view_product_${product.id}',
        localizedTitle: 'View Product ${product.name}',
      ),
    ]);
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
                    }
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
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search Accounts',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged:
                  _onSearchChanged, // Update search query when user types
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            _showForm(), // Function to show form to add accounts or products
        child: const Icon(Icons.add),
      ),
      body: ValueListenableBuilder(
        valueListenable:
            _searchQueryNotifier, // Notifier to rebuild UI on search query change
        builder: (context, searchQuery, _) {
          final filteredAccounts =
              _filterAccounts(accountsBox.values.toList(), searchQuery);

          return ListView.builder(
            itemCount: filteredAccounts.length,
            itemBuilder: (context, index) {
              // Display accounts that match the search query
              final account = filteredAccounts[index];
              final initials = getInitials(account.merchantName);

              return itemCard(context, account, initials, productBox);
            },
          );
        },
      ),
    );
  }

  Container itemCard(BuildContext context, Accounts accounts, String initials,
      var productBox) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            elevation: 2,
            child: ListTile(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CreateOrderScreen(
                      merchantName: accounts.merchantName,
                      upiId: accounts.upiId,
                      amount: 1,
                    ),
                  ),
                );
              },
              contentPadding: const EdgeInsets.all(16.0),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(accounts.color),
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              title: Text(accounts.merchantName),
              subtitle: Text(formatUpiId(accounts.upiId)),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showForm(accounts: accounts),
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showAddProductForm(context, accounts),
                padding: const EdgeInsets.all(8.0),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProductListScreen(
                        accounts: accounts,
                        productBox: productBox,
                        showEditProductForm: _showEditProductForm,
                        refreshHomeScreen: _refresh,
                      ),
                    ),
                  );
                },
                padding: const EdgeInsets.all(8.0),
              ),
            ],
          ),
          SizedBox(
            height: 110, // Adjust the height to avoid overflow
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: accounts.productIds.length,
              itemBuilder: (context, index) {
                final productId = accounts.productIds[index];
                final product = productBox.get(productId);

                return productTile(product, accounts, () {
                  setState(() {});
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  GestureDetector productTile(
      Product? product, Accounts accounts, Function() refreshCallback) {
    return GestureDetector(
      onTap: () {
        if (product != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CreateOrderScreen(
                merchantName: accounts.merchantName,
                upiId: accounts.upiId,
                amount:
                    product.price, // Passing the product price as the amount
              ),
            ),
          );
        }
      },
      child: Container(
        width: 220,
        height: 120,
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product != null && product.name.isNotEmpty
                              ? product.name
                              : 'Unknown Product',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                          ),
                          textAlign: TextAlign.left,
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          product != null
                              ? '₹${product.price.toString()}'
                              : 'Price not available',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.0,
                          ),
                          textAlign: TextAlign.left,
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          product != null && product.description.isNotEmpty
                              ? product.description
                              : 'No description available',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14.0,
                          ),
                          textAlign: TextAlign.left,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  if (product != null && product.imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: product.imageUrl.startsWith('http')
                          ? Image.network(
                              product.imageUrl,
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              File(product.imageUrl),
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            ),
                    )
                  else
                    const Icon(Icons.category, color: Colors.grey, size: 100),
                ],
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.edit, color: Colors.grey),
                onPressed: () {
                  if (product != null) {
                    _showEditProductForm(
                        context, product, accounts, refreshCallback);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
