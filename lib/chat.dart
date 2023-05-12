// Describes a stateless widget that displays a chat history and an input field with a send icon.
// The chat history is displayed using a scrollable ListView, with each row representing a single message.
// Scrolling to the top of the chat history will load more messages
// The message widget will show the user's avatar, and the message content.
// The input field will show the user's avatar, and a text field with a send icon.

// Path: lib/chat.dart

import 'package:flutter/material.dart';
import 'package:flutterfire_ui/auth.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

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
    if (kReleaseMode) {
      _chatApi =
          ChatApi(baseUrl: 'https://care-chat-api-wolbffcavq-wl.a.run.app');
    } else {
      _chatApi = ChatApi(baseUrl: 'http://localhost:3000');
    }
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
          title: const Text('Care Chat'),
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
              return ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.all(8),
                reverse: true,
                itemCount: snapshot.data!.length,
                separatorBuilder: (context, index) {
                  final thisMessage = snapshot.data![index];
                  final prevMessage = index < snapshot.data!.length - 1
                      ? snapshot.data![index + 1]
                      : null;
                  if (prevMessage != null &&
                      !isSameDate(
                          thisMessage.createdAt, prevMessage.createdAt)) {
                    return Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 2.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0),
                          color: Colors.grey[300],
                        ),
                        child: Text(
                          DateFormat('EEEE, MMMM d')
                              .format(thisMessage.createdAt),
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  } else {
                    return Container(); // empty separator
                  }
                },
                itemBuilder: (context, index) {
                  final message = snapshot.data![index];
                  return ListTile(
                    contentPadding: EdgeInsets.all(2),
                    leading: CircleAvatar(
                      child: Text(getInitials(user, message)),
                    ),
                    title: SelectableText(message.text),
                    subtitle: Text(getDisplayNameAndMessageTime(user, message)),
                  );
                },
              );
          }
        },
      );
    });
  }

  bool isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Color getTileColor(user, message) {
    if (user.uid == message.userId) {
      return Colors.white;
    } else {
      return Colors.grey[300]!;
    }
  }

  String getDisplayNameAndMessageTime(user, message) {
    String formattedTime = DateFormat('jm').format(message.createdAt);
    if (user.uid == message.userId) {
      return user.displayName + ' - ' + formattedTime;
    } else {
      return 'Bot - $formattedTime';
    }
  }

  String getInitials(user, message) {
    if (user.uid == message.userId) {
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        List<String> names = user.displayName!.split(' ');
        String initials = '';
        for (var name in names) {
          if (name.isNotEmpty) {
            initials += name[0].toUpperCase();
          }
        }
        return initials;
      } else {
        return '';
      }
    } else {
      return 'B';
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
      const Duration(seconds: 5),
      () {
        chatApi.fetchMessages(messageLimit: 50);
      },
    );
    _controller.clear();
    myFocusNode.requestFocus();
  }
}
