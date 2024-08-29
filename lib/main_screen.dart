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
    return FutureBuilder<bool>(
      future: _authenticate(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError || !snapshot.data!) {
          return Scaffold(
            body: Center(child: Text('Authentication failed')),
          );
        } else {
          return KBottom(quickActions: quickActions);
        }
        //return KBottom(quickActions: quickActions);
      },
    );
  }

  Future<bool> _authenticate() async {
    try {
      bool canCheckBiometrics = await auth.canCheckBiometrics;
      bool isAuthenticated = false;

      if (canCheckBiometrics) {
        isAuthenticated = await auth.authenticate(
          localizedReason: 'Please authenticate to access the app',
          options: const AuthenticationOptions(biometricOnly: true),
        );
      } else {
      }

      return isAuthenticated;
    } catch (e) {
      return false;
    }
  }
}
