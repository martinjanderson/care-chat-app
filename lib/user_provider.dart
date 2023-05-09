import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

// Defines a UserProvider that manages a User object with an email address and display name.
// UserProvider is a ChangeNotifier, so it can be used with ChangeNotifierProvider.
// UserProvider hydrates a User with data from FirebaseAuth.instance.currentUser.
// Path: lib/user_provider.dart

class UserProvider extends ChangeNotifier {
  UserProvider() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _user = FirebaseAuth.instance.currentUser;
      notifyListeners();
    });
  }
  // Reload the _user from FirebaseAuth.instance.currentUser and notifyListeners.
  void reload() {
    _user = FirebaseAuth.instance.currentUser;
    notifyListeners();
  }

  User? _user;

  User? get user => _user;

  String get displayName => _user?.displayName ?? 'No display name';

  String get email => _user?.email ?? 'No email address';

  String get photoURL => _user?.photoURL ?? 'No photo URL';
}
