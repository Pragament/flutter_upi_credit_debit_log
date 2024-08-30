import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:payment/home_screen.dart';
import 'package:quick_actions/quick_actions.dart';

import 'package:payment/order_list_screen.dart';
import 'package:payment/pay.dart';

class KBottom extends StatefulWidget {
  final QuickActions quickActions;
  const KBottom({
    Key? key,
    required this.quickActions,
  }) : super(key: key);

  @override
  State<KBottom> createState() => _KBottomState();
}

class _KBottomState extends State<KBottom> {
  int _selectedPageIndex = 0; // Updated variable name for clarity
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadaccounts();
  }

  Future<void> _loadaccounts() async {
    final accountsBox = Hive.box<Accounts>('accounts');
    final accounts = accountsBox.get(0);

    if (accounts != null) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
       
        backgroundColor: Colors.blue, // Customize the app bar color
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: const Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(CupertinoIcons.house_fill),
              title: const Text('Home'),
              onTap: () {
                Navigator.of(context).pop(); // Close the drawer
                setState(() {
                  _selectedPageIndex = 0;
                  _pageController.jumpToPage(0);
                });
              },
            ),
            ListTile(
              leading: Icon(CupertinoIcons.add),
              title: const Text('Transactions List'),
              onTap: () {
                Navigator.of(context).pop(); // Close the drawer
                setState(() {
                  _selectedPageIndex = 1;
                  _pageController.jumpToPage(1);
                });
              },
            ),
          ],
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedPageIndex = index;
          });
        },
        children: [
          HomeScreen(
            quickActions: widget.quickActions,
          ),
          const TransactionScreen(),
          const Scaffold(
            body: Center(
              child: Text("Settings"),
            ),
          )
        ],
      ),
    );
  }
}
