import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutterfire_ui/auth.dart';
import 'user_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.person),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute<ProfileScreen>(
                builder: (context) => ProfileScreen(
                  appBar: AppBar(
                    title: const Text('User Profile'),
                    leading: BackButton(onPressed: () {
                      Provider.of<UserProvider>(context, listen: false)
                          .reload();
                      Navigator.of(context).pop();
                    }),
                  ),
                  actions: [
                    SignedOutAction((context) {
                      Navigator.of(context).pop();
                    })
                  ],
                ),
              ),
            );
          },
        ),
        title: const Text('Chat'),
        actions: [
          const SignOutButton(),
        ],
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          children: [
            Image.asset('dash.png'),
            Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                return Text(
                  "Hello",
                  style: Theme.of(context).textTheme.displaySmall,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
