import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:payment/Create.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:payment/pay.dart';

class SettingsScreen extends StatefulWidget {
  final QuickActions quickActions;

  const SettingsScreen({Key? key, required this.quickActions})
      : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Box<Settings> settingsBox;
  Color _selectedColor = Colors.blue;
  final TextEditingController _merchantNameController = TextEditingController();
  final TextEditingController _upiIdController = TextEditingController();
  final TextEditingController _currencyController = TextEditingController();
  bool _createShortcut = false;

  @override
  void initState() {
    super.initState();
    settingsBox = Hive.box<Settings>('settings');
  }

  void _showForm({Settings? settings}) {
    if (settings != null) {
      _merchantNameController.text = settings.merchantName;
      _upiIdController.text = settings.upiId;
      _currencyController.text = settings.currency;
      _selectedColor = Color(settings.color);
      _createShortcut = settings.createShortcut;
    } else {
      _merchantNameController.clear();
      _upiIdController.clear();
      _currencyController.clear();
      _selectedColor = Colors.blue;
      _createShortcut = false;
    }

    final bool isArchived = settings?.archived ?? false;
    final DateTime? archiveDate = settings?.archiveDate;
    final bool isDeletable = !isArchived ||
        (archiveDate != null &&
            DateTime.now().difference(archiveDate).inDays >= 30);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(settings == null ? 'Add Settings' : 'Edit Settings'),
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
                if (settings != null) ...[
                  const SizedBox(height: 16.0),
                  Row(
                    children: [
                      Checkbox(
                        value: settings.archived,
                        onChanged: (value) {
                          setState(() {
                            settings.archived = value!;
                            settings.archiveDate =
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
          settings != null
              ? TextButton(
                  onPressed: () {
                    if (settings != null && !isDeletable) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'You cannot delete this account until 30 days have passed since archiving.'),
                        ),
                      );
                    } else if (settings != null) {
                      _deleteSettings(settings);
                      Navigator.of(context).pop();
                    }
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
              if (settings == null) {
                _addSettings();
              } else {
                _updateSettings(settings);
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

  Future<void> _addSettings() async {
    final id = settingsBox.isEmpty ? 0 : settingsBox.values.last.id + 1;
    final settings = Settings(
      id: id,
      merchantName: _merchantNameController.text,
      upiId: _upiIdController.text,
      currency: _currencyController.text,
      color: _selectedColor.value,
      createShortcut: _createShortcut,
      archived: false, productIds: [],
    );

    await settingsBox.put(id, settings);
    if (_createShortcut) {
      _createQuickAction(settings);
    }
    _manageQuickActions(); // Refresh the quick actions
    setState(() {});
  }

  Future<void> _updateSettings(Settings settings) async {
    settings.merchantName = _merchantNameController.text;
    settings.upiId = _upiIdController.text;
    settings.currency = _currencyController.text;
    settings.color = _selectedColor.value;
    settings.createShortcut = _createShortcut;

    if (settings.archived == false) {
      settings.archiveDate = null;
    } else if (settings.archived) {
      settings.archiveDate = DateTime.now();
    }

    await settings.save();
    _manageQuickActions(); // Refresh the quick actions
    setState(() {});
  }

  Future<void> _deleteArchivedAccounts() async {
    final now = DateTime.now();
    final itemsToDelete = settingsBox.values.where((settings) =>
        settings.archived &&
        settings.archiveDate != null &&
        now.difference(settings.archiveDate!).inDays > 30);

    for (final settings in itemsToDelete) {
      await settings.delete();
    }
  }

  Future<void> _deleteSettings(Settings settings) async {
    await settings.delete();
    _manageQuickActions(); // Refresh the quick actions
    setState(() {});
  }

  void _createQuickAction(Settings settings) {
    widget.quickActions.setShortcutItems(<ShortcutItem>[
      ShortcutItem(
        type: 'create_order_${settings.id}',
        localizedTitle: 'Create Order for ${settings.merchantName}',
        //icon: 'icon_add_order',
      ),
    ]);
  }

  void _removeQuickAction(Settings settings) {
    widget.quickActions.clearShortcutItems();
  }

  void _manageQuickActions() {
    final shortcuts = Hive.box<Settings>('settings')
        .values
        .where((settings) => settings.createShortcut)
        .map((settings) {
      return ShortcutItem(
        type: 'create_order_${settings.id}',
        localizedTitle: 'Create Order for ${settings.merchantName}',
        //icon: 'icon_add_order',
      );
    }).toList();

    widget.quickActions.setShortcutItems(shortcuts);
  }

  String _formatUpiId(String upiId) {
    if (upiId.length > 6) {
      return 'xxxxxxx${upiId.substring(upiId.length - 6)}';
    }
    return upiId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showForm(),
          ),
        ],
      ),
      body: ValueListenableBuilder<Box<Settings>>(
        valueListenable: Hive.box<Settings>('settings').listenable(),
        builder: (context, box, _) {
          return ListView.builder(
            itemCount: box.values.length,
            itemBuilder: (context, index) {
              final settings = box.getAt(index);
              final initials = settings!.merchantName
                  .split(' ')
                  .map((word) => word[0])
                  .take(2)
                  .join()
                  .toUpperCase(); // Ensure initials are in uppercase

              return Container(
                margin:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ListTile(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CreateOrderScreen(
                          merchantName: settings.merchantName,
                          upiId: settings.upiId,
                        ),
                      ),
                    );
                  },
                  contentPadding: const EdgeInsets.all(12.0),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(settings.color),
                      border: Border.all(
                        color: Colors.white, // Ensure there's enough contrast
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18, // Adjust text size if needed
                        ),
                      ),
                    ),
                  ),
                  title: Text(settings.merchantName),
                  subtitle: Text(_formatUpiId(settings.upiId)),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showForm(settings: settings),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
