// chat_room.dart
import 'message.dart';

class ChatRoom {
  final String id;
  final String ownerId;
  final String botId;
  final List<String> participantIds;
  final List<Message> messages;

  ChatRoom({
    required this.id,
    required this.ownerId,
    required this.botId,
    required this.participantIds,
    required this.messages,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    //Return a ChatRoom object from a JSON object with Messages inside
    List<Message> messages = [];
    for (var message in json['messages']) {
      messages.add(Message.fromJson(message));
    }
    return ChatRoom(
      id: json['id'],
      ownerId: json['ownerId'],
      botId: json['botId'],
      participantIds: json['participantIds'].cast<String>(),
      messages: messages,
    );
  }
}
