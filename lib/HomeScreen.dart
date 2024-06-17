import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  late List<TransactionData> transactions = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Transactions'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading transactions'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          transactions.clear();
          transactions = snapshot.data!.docs.map((doc) => TransactionData.fromSnapshot(doc)).toList();

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orangeAccent),
                ),
                child: DataTable(
                  columns: const <DataColumn>[
                    DataColumn(label: Text('Order ID')),
                    DataColumn(label: Text('Amount')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('UTR Number')),
                    DataColumn(label: Text('Client Notes')),
                    DataColumn(label: Text('Paper Bill Image')),
                    DataColumn(label: Text('UPI Receipt Image')),
                    DataColumn(label: Text('Date & Time')),
                    DataColumn(label: Text('Edit')),
                  ],
                  rows: transactions.map((transaction) {
                    return DataRow(cells: [
                      DataCell(Text(transaction.orderId)),
                      DataCell(Text(transaction.amount)),
                      DataCell(Text(transaction.status)),
                      DataCell(Text(transaction.utrNumber)),
                      DataCell(Text(transaction.clientNotes)),
                      DataCell(_buildImageWidget(transaction.paperBillImage)),
                      DataCell(_buildImageWidget(transaction.upiReceiptImage)),
                      DataCell(Text(transaction.dateTime.toString())),
                      DataCell(IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          _editTransaction(transaction);
                        },
                      )),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _editTransaction(TransactionData transaction) {
    String newAmount = transaction.amount;
    String newStatus = transaction.status;
    String newUtrNumber = transaction.utrNumber;
    String newClientNotes = transaction.clientNotes;
    File? newPaperBillImage;
    File? newUpiReceiptImage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit Transaction'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      initialValue: transaction.amount,
                      decoration: InputDecoration(labelText: 'Amount'),
                      onChanged: (value) => newAmount = value,
                    ),
                    TextFormField(
                      initialValue: transaction.status,
                      decoration: InputDecoration(labelText: 'Status'),
                      onChanged: (value) => newStatus = value,
                    ),
                    TextFormField(
                      initialValue: transaction.utrNumber,
                      decoration: InputDecoration(labelText: 'UTR Number'),
                      onChanged: (value) => newUtrNumber = value,
                    ),
                    TextFormField(
                      initialValue: transaction.clientNotes,
                      decoration: InputDecoration(labelText: 'Client Notes'),
                      onChanged: (value) => newClientNotes = value,
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                              if (pickedFile != null) {
                                setState(() {
                                  newPaperBillImage = File(pickedFile.path);
                                });
                              }
                            },
                            child: Text('Pick Paper Bill Image'),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                              if (pickedFile != null) {
                                setState(() {
                                  newUpiReceiptImage = File(pickedFile.path);
                                });
                              }
                            },
                            child: Text('Pick UPI Receipt Image'),
                          ),
                        ),
                      ],
                    ),
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
                    await _updateTransaction(
                      transaction,
                      newAmount,
                      newStatus,
                      newUtrNumber,
                      newClientNotes,
                      newPaperBillImage,
                      newUpiReceiptImage,
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

  Future<void> _updateTransaction(
      TransactionData transaction,
      String newAmount,
      String newStatus,
      String newUtrNumber,
      String newClientNotes,
      File? newPaperBillImage,
      File? newUpiReceiptImage,
      ) async {
    // Update text fields
    transaction.amount = newAmount;
    transaction.status = newStatus;
    transaction.utrNumber = newUtrNumber;
    transaction.clientNotes = newClientNotes;

    // Upload images if new images are picked
    if (newPaperBillImage != null) {
      String paperBillImageUrl = await _uploadImage(newPaperBillImage);
      transaction.paperBillImage = paperBillImageUrl;
    }
    if (newUpiReceiptImage != null) {
      String upiReceiptImageUrl = await _uploadImage(newUpiReceiptImage);
      transaction.upiReceiptImage = upiReceiptImageUrl;
    }

    // Update Firestore document
    await FirebaseFirestore.instance.collection('orders').doc(transaction.orderId).update({
      'amount': transaction.amount,
      'status': transaction.status,
      'utr_number': transaction.utrNumber,
      'client_notes': transaction.clientNotes,
      'invoice_image_url': transaction.paperBillImage,
      'transaction_image_url': transaction.upiReceiptImage,
      'date_time': DateTime.now(), // Update date and time
    });

    // Refresh UI
    setState(() {});
  }

  Future<String> _uploadImage(File imageFile) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference reference = FirebaseStorage.instance.ref().child('images/$fileName');
    UploadTask uploadTask = reference.putFile(imageFile);
    TaskSnapshot taskSnapshot = await uploadTask;
    String imageUrl = await taskSnapshot.ref.getDownloadURL();
    return imageUrl;
  }

  Widget _buildImageWidget(String? imagePath) {
    if (imagePath == null) {
      return SizedBox.shrink();
    }
    return Image.network(imagePath, width: 50, height: 50);
  }
}

class TransactionData {
  late String orderId;
  late String amount;
  late String status;
  late String utrNumber;
  late String clientNotes;
  String? paperBillImage;
  String? upiReceiptImage;
  late DateTime dateTime;

  TransactionData({
    required this.orderId,
    required this.amount,
    required this.status,
    required this.utrNumber,
    required this.clientNotes,
    this.paperBillImage,
    this.upiReceiptImage,
    required this.dateTime,
  });

  factory TransactionData.fromSnapshot(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TransactionData(
      orderId: data['order_id'] ?? '',
      amount: data['amount'] ?? '',
      status: data['status'] ?? '',
      utrNumber: data['utr_number'] ?? '',
      clientNotes: data['client_notes'] ?? '',
      paperBillImage: data['invoice_image_url'],
      upiReceiptImage: data['transaction_image_url'],
      dateTime: data['timestamp'] != null ? (data['timestamp'] as Timestamp).toDate() : DateTime.now(),
    );
  }
}
