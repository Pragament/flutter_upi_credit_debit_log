import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:payment/HomeScreen.dart';
import 'package:payment/pay.dart';
import 'package:payment/qr.dart';
import 'package:qr_flutter/qr_flutter.dart';

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

  String? _merchantName;
  String? _upiId;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settingsBox = Hive.box<Settings>('settings');
    final settings = settingsBox.get(0);

    if (settings != null) {
      setState(() {
        _merchantName = settings.merchantName;
        _upiId = settings.upiId;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _amountController.dispose();
    _clientNotesController.dispose();
    _utrController.dispose();
    super.dispose();
  }

  void _generateQrCode() {
    if (_upiId == null || _merchantName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'UPI ID or Merchant Name is missing. Please configure it in settings.')),
      );
      return;
    }

    setState(() {
      _clientTxnId = DateTime.now().millisecondsSinceEpoch.toString();
      _qrCodeData =
          'upi://pay?pa=$_upiId&pn=$_merchantName&am=${_amountController.text}&tn=$_clientTxnId&cu=INR';
      _startTimer();
    });
  }

  void _startTimer() {
    _secondsLeft = 120;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft == 0) {
        _generateQrCode(); // Automatically regenerate QR code when time is up
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
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (!mounted) return; // Ensure the widget is still mounted

      if (pickedFile != null) {
        setState(() {
          _invoiceImage = pickedFile.path;
        });
      } else {
        // Handle the case when no image is selected
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No image selected')),
        );
      }
    } catch (e) {
      // Log the error and show a snackbar
      if (!mounted) return; // Ensure the widget is still mounted

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _pickTransactionImage() async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (!mounted) return; // Ensure the widget is still mounted

      if (pickedFile != null) {
        setState(() {
          _transactionImage = pickedFile.path;
        });
      } else {
        // Handle the case when no image is selected
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No image selected')),
        );
      }
    } catch (e) {
      // Log the error and show a snackbar
      if (!mounted) return; // Ensure the widget is still mounted

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

      final order = Order()
        ..orderId = _clientTxnId!
        ..amount = _amountController.text
        ..clientNotes = _clientNotesController.text
        ..qrCodeUrl = qrPath
        ..invoiceImageUrl = _invoiceImage!
        ..transactionImageUrl = _transactionImage!
        ..utrNumber = _utrController.text
        ..status = 'pending'
        ..timestamp = DateTime.now();

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
      });

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
      MaterialPageRoute(builder: (context) => const QrScannerScreen()),
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
      return const SizedBox.shrink();
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
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _generateQrCode,
              child: const Text('Generate QR Code'),
            ),
            const SizedBox(height: 16.0),
            if (_qrCodeData != null) ...[
              Text('QR Code will expire in $_secondsLeft seconds'),
              const SizedBox(height: 16.0),
              _buildQRCodeWidget(),
            ],
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _pickInvoiceImage,
              child: const Text('Upload Invoice Image'),
            ),
            if (_invoiceImage != null)
              Image.file(File(_invoiceImage!), height: 100.0, width: 100.0),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _pickTransactionImage,
              child: const Text('Upload Transaction Image'),
            ),
            if (_transactionImage != null)
              Image.file(File(_transactionImage!), height: 100.0, width: 100.0),
            const SizedBox(height: 16.0),
            TextField(
              controller: _utrController,
              decoration: const InputDecoration(labelText: 'UTR Number'),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _uploadOrder,
              child: const Text('Create Order'),
            ),
          ],
        ),
      ),
    );
  }
}
