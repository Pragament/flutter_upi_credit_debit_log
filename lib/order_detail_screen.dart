import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:payment/pay.dart';

class OrderDetailsScreen extends StatelessWidget {
  final Order order;

  const OrderDetailsScreen({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
            const Spacer(),

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
            const SizedBox(height: 16),

            // View & Share PDF Button
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  final pdfFile = await _generatePdf();
                  final directory = await getApplicationDocumentsDirectory();
                  final filePath =
                      '${directory.path}/invoice_${order.timestamp.millisecondsSinceEpoch}.pdf';
                  final file = File(filePath);
                  await file.writeAsBytes(await pdfFile.save());

                  // Convert file path to XFile
                  final xFile = XFile(filePath);

                  // Share the PDF file
                  await Share.shareXFiles([xFile],
                      text: 'Here is your invoice for the order.');
                },
                child: const Text('View & Share PDF Invoice'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<pw.Document> _generatePdf() async {
    final pdf = pw.Document();
    final productBox = Hive.box<Product>('products');
    final accountsBox = Hive.box<Accounts>('accounts');
    String? bgShape = await rootBundle.loadString(
        'assets/invoice.svg'); // Assuming accounts are stored in Hive

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          final account = accountsBox.values.cast<Accounts?>().firstWhere(
                (acc) =>
                    acc?.productIds
                        .any((id) => order.products.containsKey(id)) ??
                    false,
                orElse: () => null, // Provide a fallback if no account is found
              );

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                  child: pw.Container(
                color: PdfColors.blue,
                padding: const pw.EdgeInsets.all(10),
                child: pw.Text(
                  'Invoice',
                  style: pw.TextStyle(
                    fontSize: 32,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              )),

              pw.SizedBox(height: 20),
              pw.Text('Status: ${order.status}',
                  style: const pw.TextStyle(fontSize: 18)),
              pw.SizedBox(height: 20),
              pw.Container(
                color: PdfColors.blue,
                padding: const pw.EdgeInsets.all(10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Invoice number: ${order.orderId}',
                        style: const pw.TextStyle(fontSize: 18)),
                    pw.Text(
                        'Placed at: ${DateFormat('d MMMM yyyy, h:mma').format(order.timestamp)}',
                        style: const pw.TextStyle(fontSize: 18)),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),
              pw.Text('Number of Products: ${order.products.length}',
                  style: const pw.TextStyle(fontSize: 18)),
              pw.SizedBox(height: 20),

              if (account != null) ...[
                pw.Text('Merchant Name: ${account.merchantName}',
                    style: const pw.TextStyle(fontSize: 18)),
                pw.Text('UPI ID: ${account.upiId}',
                    style: const pw.TextStyle(fontSize: 18)),
                pw.SizedBox(height: 20),
              ],

              // Product Table Header
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.blueGrey700, // Header color
                      borderRadius:
                          pw.BorderRadius.vertical(top: pw.Radius.circular(10)),
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8.0),
                        child: pw.Text('Product',
                            style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white),
                            textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8.0),
                        child: pw.Text('Quantity',
                            style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white),
                            textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8.0),
                        child: pw.Text('Price per Item',
                            style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white),
                            textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8.0),
                        child: pw.Text('Total',
                            style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white),
                            textAlign: pw.TextAlign.center),
                      ),
                    ],
                  ),
                  ...order.products.keys.map((productId) {
                    final product = productBox.get(productId);
                    final quantity = order.products[productId];
                    final totalPrice =
                        product != null ? product.price * quantity! : 0.0;

                    return pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(
                            color: PdfColors.blueGrey100,
                            width: 1.0,
                          ),
                        ),
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text(product?.name ?? 'N/A',
                              textAlign: pw.TextAlign.center),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text('$quantity',
                              textAlign: pw.TextAlign.center),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text(
                              product?.price.toStringAsFixed(2) ?? 'N/A',
                              textAlign: pw.TextAlign.center),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text(totalPrice.toStringAsFixed(2),
                              textAlign: pw.TextAlign.center),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),

              pw.SizedBox(height: 20),
              pw.Text('Total Amount: ${order.amount}',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),

              pw.Text('Scan the QR code to pay:',
                  style: const pw.TextStyle(fontSize: 18)),
              pw.SizedBox(height: 10),

              // Load and display the QR code image from file
              pw.Image(
                pw.MemoryImage(File(order.qrCodeUrl).readAsBytesSync()),
                width: 100,
                height: 100,
              ),

              // Footer Content
              pw.Spacer(), // Pushes footer to the bottom
              pw.Container(
                height: 100, // Adjust the height as needed
                width: double.infinity,
                child: pw.SvgImage(
                  svg: bgShape,
                  fit: pw.BoxFit.cover,
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }
}
