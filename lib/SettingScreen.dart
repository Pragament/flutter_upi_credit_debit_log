import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _upiIdController = TextEditingController();
  String? _selectedCurrency;

  final List<String> _currencies = ['INR', 'USD', 'EUR', 'GBP'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('settings').doc('default').get();
    if (snapshot.exists) {
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      setState(() {
        _nameController.text = data['merchant_name'];
        _upiIdController.text = data['upi_id'];
        String savedCurrency = data['currency'];

        if (_currencies.contains(savedCurrency)) {
          _selectedCurrency = savedCurrency;
        } else {
          _selectedCurrency = _currencies.first;
        }
      });
    }
  }

  void _saveSettings() async {
    await FirebaseFirestore.instance.collection('settings').doc('default').set({
      'merchant_name': _nameController.text,
      'upi_id': _upiIdController.text,
      'currency': _selectedCurrency,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved')),
    );

    // Reset UI fields
    _nameController.clear();
    _upiIdController.clear();
    _selectedCurrency = null;
    setState(() {}); // Update UI
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Merchant/Payee Name'),
            ),
            TextField(
              controller: _upiIdController,
              decoration: const InputDecoration(labelText: 'Payee UPI ID'),
            ),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Currency'),
              value: _selectedCurrency,
              items: _currencies.map((currency) {
                return DropdownMenuItem<String>(
                  value: currency,
                  child: Text(currency),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedCurrency = newValue;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveSettings,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
