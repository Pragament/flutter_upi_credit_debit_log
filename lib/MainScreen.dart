import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:payment/KBottom.dart';
import 'HomeScreen.dart';

class MainScreen extends StatelessWidget {
  final LocalAuthentication auth = LocalAuthentication();

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
          return KBottom();
        }
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
        print('Biometric authentication is not available on this device.');
      }

      return isAuthenticated;
    } catch (e) {
      print('Error during authentication: $e');
      return false;
    }
  }
}
