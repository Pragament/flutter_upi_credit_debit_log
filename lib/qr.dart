import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:payment/pay.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:path_provider/path_provider.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({Key? key}) : super(key: key);

  @override
  _QrScannerScreenState createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String? qrCodeResult;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    } else if (Platform.isIOS) {
      controller!.resumeCamera();
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      setState(() {
        qrCodeResult = scanData.code;
      });

      // Save the scanned QR code result to Hive database
      if (qrCodeResult != null) {
        final directory = await getApplicationDocumentsDirectory();
        await Hive.initFlutter(directory.path);

        final orderBox = Hive.box<Order>('orders');

        final newOrder = Order()
          ..orderId = DateTime.now().millisecondsSinceEpoch.toString()
          ..amount = '0'
          ..clientNotes = ''
          ..qrCodeUrl = qrCodeResult!
          ..invoiceImageUrl = ''
          ..transactionImageUrl = ''
          ..utrNumber = ''
          ..status = 'pending'
          ..timestamp = DateTime.now();

        await orderBox.add(newOrder);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('QR Code saved successfully')),
        );
      }

      // Navigate back to the previous screen with the scanned result
      Navigator.pop(context, qrCodeResult);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: Colors.red,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 300,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                qrCodeResult != null
                    ? 'Result: $qrCodeResult'
                    : 'Scan a code',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
