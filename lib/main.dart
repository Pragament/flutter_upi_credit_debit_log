import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:payment/HomeScreen.dart';
import 'package:payment/MainScreen.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:payment/Create.dart';
import 'package:payment/pay.dart';

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
  Hive.registerAdapter(ProductAdapter());

  // Open boxes for orders, settings, and products
  await Hive.openBox<Order>('orders');
  await Hive.openBox<Settings>('settings');
  await Hive.openBox<Product>('products');

  // Initialize Quick Actions
  final QuickActions quickActions = QuickActions();
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
    } else if (shortcutType.startsWith('view_product_')) {
      final productId = int.parse(shortcutType.split('_').last);

      // Fetch the actual product for the given productId
      final productsBox = Hive.box<Product>('products');
      final product = productsBox.get(productId);

      if (product != null) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => HomeScreen(), // Assuming HomeScreen shows product details
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
