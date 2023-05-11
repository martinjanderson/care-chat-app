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
import 'dart:async';
import 'package:provider/provider.dart';

import 'user_provider.dart';
import 'chat_api.dart';
import 'message.dart';

// A new InheritedWidget that provides a ChatApi to its descendants.
// This is used to provide the ChatApi to the MessageList and MessageInput widgets.
class ChatApiProvider extends InheritedWidget {
  final ChatApi chatApi;

  ChatApiProvider({
    Key? key,
    required this.chatApi,
    required Widget child,
  }) : super(key: key, child: child);

  static ChatApiProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ChatApiProvider>();
  }

  @override
  bool updateShouldNotify(ChatApiProvider old) => chatApi != old.chatApi;
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late ChatApi _chatApi;

  @override
  void initState() {
    super.initState();
    _chatApi = ChatApi(baseUrl: 'http://localhost:3000');
  }

  @override
  void dispose() {
    _chatApi.dispose();
    super.dispose();
  }

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
        body: ChatApiProvider(
          chatApi: _chatApi,
          child: Column(
            children: [
              Expanded(
                child: MessageList(),
              ),
              const Divider(height: 1),
              MessageInput(),
            ],
          ),
        ));
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
      ChatApi chatApi = ChatApiProvider.of(context)!.chatApi;
      chatApi.fetchMessages(messageLimit: 50);

      return StreamBuilder<List<Message>>(
        stream: chatApi.messageStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return Text('Loading...');
            default:
              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8),
                reverse: true,
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final message = snapshot.data![index];

                  return Card(
                      child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          NetworkImage('http://localhost:3000/avatar/$userId'),
                    ),
                    title: Text(getDisplayName(user, message)),
                    subtitle: Text(message.text),
                    tileColor: getTileColor(user, message),
                  ));
                },
              );
          }
        },
      );
    });
  }

  Color getTileColor(user, message) {
    if (user.uid == message.userId) {
      return Colors.blue[100]!;
    } else {
      return Colors.grey[300]!;
    }
  }

  String getDisplayName(user, message) {
    if (user.uid == message.userId) {
      return user.displayName;
    } else {
      return 'Bot';
    }
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
      ChatApi chatApi = ChatApiProvider.of(context)!.chatApi;
      final user = userProvider.user;
      return Row(
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: (event) => submitMessage(chatApi),
              focusNode: myFocusNode,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Enter a message',
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () => submitMessage(chatApi),
          ),
          const SizedBox(width: 8),
        ],
      );
    });
  }

  // An async function that submits the message Firestore.
  void submitMessage(ChatApi chatApi) async {
    final text = _controller.text;
    if (text.isEmpty) {
      return;
    }
    await chatApi.submitMessage(text: text);
    chatApi.fetchMessages(messageLimit: 50);
    final timer = Timer(
      const Duration(seconds: 4),
      () {
        chatApi.fetchMessages(messageLimit: 50);
      },
    );
    _controller.clear();
    myFocusNode.requestFocus();
  }
}
