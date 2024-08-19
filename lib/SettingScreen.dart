import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:payment/pay.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _merchantNameController = TextEditingController();
  final TextEditingController _upiIdController = TextEditingController();
  final TextEditingController _currencyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settingsBox = Hive.box<Settings>('settings');
    final settings = settingsBox.get(0);

    if (settings != null) {
      _merchantNameController.text = settings.merchantName;
      _upiIdController.text = settings.upiId;
      _currencyController.text = settings.currency;
    }
  }

  Future<void> _saveSettings() async {
    final settingsBox = Hive.box<Settings>('settings');
    final settings = Settings(
      merchantName: _merchantNameController.text,
      upiId: _upiIdController.text,
      currency: _currencyController.text,
    );

    await settingsBox.put(0, settings);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Settings saved successfully!')),
    );

    // Clear the text fields after saving
    _merchantNameController.clear();
    _upiIdController.clear();
    _currencyController.clear();
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
            ElevatedButton(
              onPressed: _saveSettings,
              child: const Text('Save Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
