import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:payment/bottom_navbar.dart';

class MainScreen extends StatelessWidget {
  final QuickActions quickActions;

  final LocalAuthentication auth = LocalAuthentication();

  MainScreen({super.key, required this.quickActions});

  @override
  Widget build(BuildContext context) {
    return KBottom(quickActions: quickActions);
  }
}
