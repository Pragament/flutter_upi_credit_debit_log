import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:quick_actions/quick_actions.dart';

import 'package:payment/Create.dart';
import 'package:payment/HomeScreen.dart';
import 'package:payment/pay.dart';
import 'package:payment/settings_Screen.dart';

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
          const HomeScreen(), // Replace with your Home screen widget
          CreateOrderScreen(
            merchantName: _merchantName ?? '', // Pass default value if null
            upiId: _upiId ?? '', // Pass default value if null
          ),
          SettingsScreen(
            quickActions: widget.quickActions, // Pass the QuickActions instance
          ),
        ],
      ),
      bottomNavigationBar: AnimatedBottomNavigationBar(
        backgroundColor: Colors.blue.withOpacity(0.50), // Update with your color
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
