// main.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:payment/KBottom.dart';
import 'package:payment/MainScreen.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:payment/Create.dart';
import 'package:payment/HomeScreen.dart';
import 'package:payment/pay.dart';
import 'package:payment/settings_Screen.dart';

// Global key for navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive and open boxes
  final appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);

  Hive.registerAdapter(OrderAdapter());
  Hive.registerAdapter(SettingsAdapter());

  await Hive.openBox<Order>('orders');
  await Hive.openBox<Settings>('settings');

  // Initialize Quick Actions
  const QuickActions quickActions = QuickActions();
  quickActions.initialize((String shortcutType) {
    if (shortcutType.startsWith('create_order_')) {
      final accountId = int.parse(shortcutType.split('_').last);

      // Fetch the actual settings for the given accountId
      final settingsBox = Hive.box<Settings>('settings');
      final settings = settingsBox.get(accountId);

      if (settings != null) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => CreateOrderScreen(
              merchantName: settings.merchantName,
              upiId: settings.upiId,
            ),
          ),
        );
      }
    }
  });

  runApp(MyApp(quickActions: quickActions));
}

class MyApp extends StatelessWidget {
  final QuickActions quickActions;

  const MyApp({super.key, required this.quickActions});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // Use the global key here
      debugShowCheckedModeBanner: false,
      home: MainScreen(quickActions: quickActions), // Use MainScreen as the initial route
    );
  }
}
