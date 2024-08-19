import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:payment/Create.dart';
import 'package:payment/HomeScreen.dart';
import 'package:payment/settings_Screen.dart';

class KBottom extends StatefulWidget {
  const KBottom({Key? key}) : super(key: key);

  @override
  State<KBottom> createState() => _KBottomState();
}

class _KBottomState extends State<KBottom> {
  int _bottomNavIndex = 0;
  final PageController _pageController = PageController();

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
        children: const [
          HomeScreen(),      // Replace with your Home screen widget
          CreateOrderScreen(), // Replace with your Create screen widget
          SettingsScreen(),   // Replace with your Settings screen widget
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
        // gapWidth: 50,
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
