// chat_api.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'room.dart';
import 'message.dart';

class ChatApi {
  final String baseUrl;
  late Room _room;

  ChatApi({required this.baseUrl});

  final _messageStreamController = StreamController<List<Message>>();

  void dispose() {
    _messageStreamController.close();
  }

  Stream<List<Message>> get messageStream => _messageStreamController.stream;

  Future<void> fetchMessages({required int messageLimit}) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _messageStreamController.add([]);
    }
    String idToken = await user!.getIdToken();
    final response = await http.get(
        Uri.parse('$baseUrl/api/room?messageLimit=$messageLimit'),
        headers: {
          'Authorization': 'Bearer $idToken',
        });
    if (response.statusCode == 200) {
      _room = Room.fromJson(jsonDecode(response.body));
      _messageStreamController.add(_room.messages);
    } else {
      throw Exception('Failed to load chat room');
    }
  }

  Future<Message> submitMessage({required String text}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user signed in');
    }
    MessageInput input = MessageInput(text: text);
    final idToken = await user.getIdToken();
    String roomId = _room.id;
    final response = await http.post(
      Uri.parse('$baseUrl/api/room/$roomId/messages'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(input.toJson()),
    );

    if (response.statusCode == 200) {
      return Message.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized for access to this room');
    } else if (response.statusCode == 500) {
      throw Exception('Internal Server Error');
    } else if (response.statusCode == 404) {
      throw Exception('Room not found');
    } else {
      throw Exception('Failed to submit message');
    }
  }
}
