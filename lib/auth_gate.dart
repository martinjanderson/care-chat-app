import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutterfire_ui/auth.dart';

import 'chat.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || FirebaseAuth.instance.currentUser == null) {
          return SignInScreen(
              providerConfigs: const [
                EmailProviderConfiguration(),
              ],
              sideBuilder: (context, constraints) {
                return Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Care Chat',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 80,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Demo App: v0.0.1',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 16,
                                fontStyle: FontStyle.italic),
                          ),
                        ]));
              },
              showAuthActionSwitch: false);
        }

        return const ChatScreen();
      },
    );
  }
}
