import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:payment/home_screen.dart';
import 'package:quick_actions/quick_actions.dart';


import 'package:payment/transaction_screen.dart';
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
  int _bottomNavIndex = 0;
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
      setState(() {
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _bottomNavIndex = index;
          });
        },
        children: [
          // Replace with your Home screen widget

          HomeScreen(
            quickActions: widget.quickActions, // Pass the QuickActions instance
          ),
          const TransactionScreen(),
          
        ],
      ),
      bottomNavigationBar: AnimatedBottomNavigationBar(
        backgroundColor:
            Colors.blue.withOpacity(0.50), // Update with your color
        elevation: 0,
        splashColor: Colors.green, // Update with your color
        icons: const [
          CupertinoIcons.house_fill,
          CupertinoIcons.add,
          CupertinoIcons.settings,
        ],
        inactiveColor: Colors.white, // Update with your color
        activeColor: Colors.yellow, // Update with your color
        activeIndex: _bottomNavIndex,
        notchSmoothness: NotchSmoothness.smoothEdge,
        leftCornerRadius: 0,
        rightCornerRadius: 0,
        onTap: (index) {
          setState(() {
            _bottomNavIndex = index;
            _pageController.jumpToPage(index);
          });
        },
      ),
    );
  }
}
