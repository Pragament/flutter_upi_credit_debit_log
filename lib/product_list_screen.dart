import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:payment/create_order_screen.dart';
import 'package:payment/pay.dart';

class ProductListScreen extends StatefulWidget {
  final Accounts accounts;
  final Box<Product> productBox;
  final Function(BuildContext, Product, Accounts, Function())
      showEditProductForm;
  final Function() refreshHomeScreen; // New callback to refresh HomeScreen

  const ProductListScreen({
    Key? key,
    required this.accounts,
    required this.productBox,
    required this.showEditProductForm,
    required this.refreshHomeScreen, // Accept the callback
  }) : super(key: key);

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  void _refresh() {
    setState(() {});
    widget.refreshHomeScreen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.accounts.merchantName} Products'),
      ),
      body: widget.accounts.productIds.isNotEmpty ?ListView.builder(
        itemCount: widget.accounts.productIds.length,
        itemBuilder: (context, index) {
          final productId = widget.accounts.productIds[index];
          final product = widget.productBox.get(productId);

          return _buildProductTile(context, product, widget.accounts);
        },
      ):const Center(child: Text("No products added")),
    );
  }

  GestureDetector _buildProductTile(
      BuildContext context, Product? product, Accounts accounts) {
    return GestureDetector(
      onTap: () {
        if (product != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CreateOrderScreen(
                account: accounts,products: [product],
              ),
            ),
          );
        }
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product?.name ?? 'Unknown Product',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    product != null
                        ? '₹${product.price.toStringAsFixed(2)}'
                        : 'Price not available',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16.0,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    product?.description ?? 'No description available',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14.0,
                    ),
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
                        height: 60,
                        width: 60,
                        fit: BoxFit.cover,
                      )
                    : Image.file(
                        File(product.imageUrl),
                        height: 60,
                        width: 60,
                        fit: BoxFit.cover,
                      ),
              )
            else
              const Icon(Icons.image_not_supported,
                  color: Colors.grey, size: 60),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.grey),
              onPressed: () {
                if (product != null) {
                  widget.showEditProductForm(
                      context, product, accounts, _refresh);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
