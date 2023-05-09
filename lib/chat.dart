// Describes a stateless widget that displays a chat history and an input field with a send icon.
// The chat history is displayed using a scrollable ListView, with each row representing a single message.
// Scrolling to the top of the chat history will load more messages
// The message widget will show the user's avatar, and the message content.
// The input field will show the user's avatar, and a text field with a send icon.

// Path: lib/chat.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutterfire_ui/auth.dart';
import 'package:provider/provider.dart';

import 'user_provider.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({Key? key});

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
      ),
      body: Column(
        children: [
          Expanded(
            child: MessageList(),
          ),
          const Divider(height: 1),
          MessageInput(),
        ],
      ),
    );
  }
}

class MessageList extends StatefulWidget {
  const MessageList({Key? key});

  @override
  _MessageListState createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(builder: (context, userProvider, child) {
      final user = userProvider.user;
      final userId = user?.uid ?? 'null_id';
      testQuery(userId);

      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('messages')
            .where('user.uid', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .limit(20)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final messages = snapshot.data!.docs;

          return ListView.builder(
            controller: _scrollController,
            reverse: true,
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final data = message.data() as Map<String, dynamic>;
              final user = data['user'] as Map<String, dynamic>;
              final uid = user['uid'] as String;
              final displayName = user['displayName'] as String;
              final photoURL = user['photoURL'] ?? '';
              final text = data['text'] as String;

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(photoURL),
                ),
                title: Text(displayName),
                subtitle: Text(text),
              );
            },
          );
        },
      );
    });
  }
}

class MessageInput extends StatefulWidget {
  const MessageInput({Key? key});

  @override
  _MessageInputState createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _controller = TextEditingController();
  FocusNode myFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(builder: (context, userProvider, child) {
      final user = userProvider.user;
      return Row(
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: (event) => submitMessage(user),
              focusNode: myFocusNode,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Enter a message',
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () => submitMessage(user),
          ),
          const SizedBox(width: 8),
        ],
      );
    });
  }

  // An async function that submits the message Firestore.
  void submitMessage(User? user) async {
    final text = _controller.text;
    if (text.isEmpty) {
      return;
    }
    final uid = user!.uid;
    final displayName = user.displayName;
    final photoURL = user.photoURL;

    final data = {
      'user': {
        'uid': uid,
        'displayName': displayName,
        'photoURL': photoURL,
      },
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance.collection('messages').add(data);

    _controller.clear();
    myFocusNode.requestFocus();
  }
}

void testQuery(userId) {}
