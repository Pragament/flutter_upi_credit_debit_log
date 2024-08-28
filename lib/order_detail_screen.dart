import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
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
                  final filePath = '${directory.path}/invoice_${order.timestamp.millisecondsSinceEpoch}.pdf';
                  final file = File(filePath);
                  await file.writeAsBytes(await pdfFile.save());

                  // Convert file path to XFile
                  final xFile = XFile(filePath);

                  // Share the PDF file
                  await Share.shareXFiles([xFile], text: 'Here is your invoice for the order.');
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

  pdf.addPage(
    pw.Page(
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Order Details', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Text('Status: ${order.status}', style: const pw.TextStyle(fontSize: 18)),
            pw.Text('Placed at: ${DateFormat('d MMMM yyyy, h:mma').format(order.timestamp)}', style: const pw.TextStyle(fontSize: 18)),
            pw.SizedBox(height: 20),
            pw.Text('Number of Products: ${order.products.length}', style: const pw.TextStyle(fontSize: 18)),
            pw.SizedBox(height: 20),
            pw.ListView.builder(
              itemCount: order.products.length,
              itemBuilder: (context, index) {
                final productId = order.products.keys.toList()[index];
                final product = productBox.get(productId);
                return product != null
                    ? pw.Row(
                        children: [
                          pw.Image(pw.MemoryImage(File(product.imageUrl).readAsBytesSync()), width: 60, height: 60),
                          pw.SizedBox(width: 10),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(product.name, style: const pw.TextStyle(fontSize: 16)),
                              pw.Text('Price: ${product.price}', style: const pw.TextStyle(fontSize: 16)),
                            ],
                          ),
                        ],
                      )
                    : pw.SizedBox();
              },
            ),
            pw.SizedBox(height: 20),
            pw.Text('Total Amount: ${order.amount}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),

            // Add the QR code to the PDF
            pw.Text('Scan the QR code for more details:', style: pw.TextStyle(fontSize: 18)),
            pw.SizedBox(height: 10),
            
            // Load and display the QR code image from file
            pw.Image(
              pw.MemoryImage(File(order.qrCodeUrl).readAsBytesSync()), 
              width: 100, 
              height: 100,
            ),
          ],
        );
      },
    ),
  );

  return pdf;
}

}
