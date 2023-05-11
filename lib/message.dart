// message.dart
class Message {
  final String id;
  final String userId;
  final String text;
  // final DateTime createdAt;

  Message({
    required this.id,
    required this.userId,
    required this.text,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    if (json['id'] is! String) {
      throw Exception('Expected id to be a String');
    }
    if (json['userId'] is! String) {
      throw Exception('Expected userId to be a String');
    }
    if (json['text'] is! String) {
      throw Exception('Expected text to be a String');
    }

    return Message(
      id: json['id'],
      userId: json['userId'],
      text: json['text'],
      // DateTime.parse(json['createdAt']),
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
