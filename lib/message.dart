// message.dart
class Message {
  final String id;
  final String userId;
  final String text;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.userId,
    required this.text,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    int seconds = json['createdAt']['_seconds'];
    int nanoseconds = json['createdAt']['_nanoseconds'];
    int milliseconds = seconds * 1000 + nanoseconds ~/ 1000000;

    DateTime createdAt = DateTime.fromMillisecondsSinceEpoch(milliseconds);

    return Message(
      id: json['id'],
      userId: json['userId'],
      text: json['text'],
      createdAt: createdAt,
    );
  }
}

class MessageInput {
  final String text;

  MessageInput({required this.text});

  Map<String, dynamic> toJson() => {
        'text': text,
      };
}
