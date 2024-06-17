import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'HomeScreen.dart'; // Ensure HomeScreen is implemented
import 'qr scanner.dart'; // Adjusted import to your specific file

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({Key? key}) : super(key: key);

  @override
  _CreateOrderScreenState createState() => _CreateOrderScreenState();
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

  @override
  void dispose() {
    _timer?.cancel();
    _amountController.dispose();
    _clientNotesController.dispose();
    _utrController.dispose();
    super.dispose();
  }

  void _generateQrCode() {
    setState(() {
      _clientTxnId = DateTime.now().millisecondsSinceEpoch.toString();
      _qrCodeData =
      'upi://pay?pa=8639745462@ybl&pn=payeename&am=${_amountController.text}&tn=$_clientTxnId&cu=INR';
      _startTimer();
    });
  }

  void _startTimer() {
    _secondsLeft = 120;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft == 0) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _qrCodeData = null;
            _clientTxnId = null;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _secondsLeft--;
          });
        }
      }
    });
  }

  Future<void> _pickInvoiceImage() async {
    final pickedFile =
    await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _invoiceImage = pickedFile.path;
      });
    }
  }

  Future<void> _pickTransactionImage() async {
    final pickedFile =
    await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _transactionImage = pickedFile.path;
      });
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
    if (!mounted) return; // Check if the widget is still mounted

    if (_amountController.text.isEmpty ||
        _qrCodeData == null ||
        _invoiceImage == null ||
        _utrController.text.isEmpty ||
        _transactionImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all details')),
      );
      return;
    }

    try {
      // Upload QR Code Image if not already saved
      final directory = await getApplicationDocumentsDirectory();
      final qrPath = '${directory.path}/qr_code.png';
      final qrFile = File(qrPath);

      if (!qrFile.existsSync()) {
        await _saveQrCodeImage();
      }

      if (!qrFile.existsSync()) {
        throw Exception('QR Code file does not exist.');
      }

      final qrStorageRef = FirebaseStorage.instance
          .ref()
          .child('qr_codes/$_clientTxnId.png');
      final qrUploadTask = qrStorageRef.putFile(qrFile);
      final qrUrl = await (await qrUploadTask).ref.getDownloadURL();

      // Upload Invoice Image
      final invoiceFile = File(_invoiceImage!);

      if (!invoiceFile.existsSync()) {
        throw Exception('Invoice image file does not exist.');
      }

      final invoiceStorageRef = FirebaseStorage.instance
          .ref()
          .child('invoices/$_clientTxnId.png');
      final invoiceUploadTask = invoiceStorageRef.putFile(invoiceFile);
      final invoiceUrl =
      await (await invoiceUploadTask).ref.getDownloadURL();

      // Upload Transaction Image
      final transactionFile = File(_transactionImage!);

      if (!transactionFile.existsSync()) {
        throw Exception('Transaction image file does not exist.');
      }

      final transactionStorageRef = FirebaseStorage.instance
          .ref()
          .child('transactions/$_clientTxnId.png');
      final transactionUploadTask =
      transactionStorageRef.putFile(transactionFile);
      final transactionUrl =
      await (await transactionUploadTask).ref.getDownloadURL();

      // Determine status based on transaction completion
      String status = 'pending';
      // Assume transaction is complete if all required fields are filled
      if (_amountController.text.isNotEmpty &&
          _qrCodeData != null &&
          _invoiceImage != null &&
          _transactionImage != null &&
          _utrController.text.isNotEmpty) {
        status = 'complete';
      }

      // Save order details to Firestore
      await FirebaseFirestore.instance.collection('orders').add({
        'order_id': _clientTxnId,
        'amount': _amountController.text,
        'client_notes': _clientNotesController.text,
        'qr_code_url': qrUrl,
        'invoice_image_url': invoiceUrl,
        'transaction_image_url': transactionUrl,
        'utr_number': _utrController.text,
        'status': status,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order created successfully')),
      );

      // Clear form fields and UI state
      _amountController.clear();
      _clientNotesController.clear();
      _utrController.clear();
      setState(() {
        _qrCodeData = null;
        _clientTxnId = null;
        _invoiceImage = null;
        _transactionImage = null;
      });

      // Navigate to home screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create order: $e')),
      );
    }
  }

  Future<void> _scanQrCode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QrScannerScreen()),
    );

    if (result != null) {
      setState(() {
        _qrCodeData = result;
      });
    }
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
      return SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Create Order'),
        ),
        body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
              TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _clientNotesController,
              decoration: const InputDecoration(labelText: 'Client Notes'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickInvoiceImage,
              child: const Text('Pick Invoice Image'),
            ),
            if (_invoiceImage != null) Image.file(File(_invoiceImage!)),
    const SizedBox(height: 20),
    ElevatedButton(
    onPressed: _generateQrCode,
    child: const Text('Generate QR Code'),
    ),
    ElevatedButton(
    onPressed: _scanQrCode,
    child: const Text('Scan QR Code'),
    ),
    _buildQRCodeWidget(),
    if (_qrCodeData != null) ...[
    Text('Expires in $_secondsLeft seconds'),
    ElevatedButton(
    onPressed: _generateQrCode,
    child: const Text('              Regenerate QR Code'),
    ),
      ElevatedButton(
        onPressed: () {
          setState(() {
            _qrCodeData = null;
            _clientTxnId = null;
          });
        },
        child: const Text('Cancel'),
      ),
      TextField(
        controller: _utrController,
        decoration: const InputDecoration(labelText: 'UTR Number'),
      ),
      ElevatedButton(
        onPressed: _pickTransactionImage,
        child: const Text('Upload Transaction Image'),
      ),
      if (_transactionImage != null)
        Image.file(File(_transactionImage!)),
      const SizedBox(height: 20),
      ElevatedButton(
        onPressed: _uploadOrder,
        child: const Text('Upload Order'),
      ),
    ],
              ],
            ),
        ),
    );
  }
}

