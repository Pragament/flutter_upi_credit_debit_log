import 'package:local_auth/local_auth.dart';

String formatUpiId(String upiId) {
  if (upiId.length > 6) {
    return 'xxxxxxx${upiId.substring(upiId.length - 6)}';
  }
  return upiId;
}

String getInitials(String merchantName) {
  if (merchantName.isEmpty) {
    return 'NA'; // Default initials if merchant name is empty
  }
  final words =
      merchantName.split(' ').where((word) => word.isNotEmpty).toList();
  if (words.isEmpty) {
    return 'NA'; // Default initials if no valid words are present
  }
  return words
      .take(2)
      .map((word) => word.isNotEmpty ? word[0] : '')
      .join()
      .toUpperCase();
}

class BiometricAuth {
  final LocalAuthentication auth = LocalAuthentication();
  Future<bool> authenticate() async {
    try {
      bool canCheckBiometrics = await auth.canCheckBiometrics;
      bool isAuthenticated = false;

      if (canCheckBiometrics) {
        isAuthenticated = await auth.authenticate(
          localizedReason: 'Please authenticate to access the app',
          options: const AuthenticationOptions(biometricOnly: true),
        );
      } else {}

      return isAuthenticated;
    } catch (e) {
      return false;
    }
  }
}
