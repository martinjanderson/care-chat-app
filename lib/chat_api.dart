// chat_api.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'room.dart';
import 'message.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatApi {
  final String baseUrl;
  final String urlProtocol;
  late Room _room;
  late IO.Socket socket;

  ChatApi({required this.baseUrl, required this.urlProtocol});

  final _messageStreamController = StreamController<List<Message>>();

  void dispose() {
    _messageStreamController.close();
    socket.dispose();
  }

  Stream<List<Message>> get messageStream => _messageStreamController.stream;

  Future<void> fetchMessages({required int messageLimit}) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _messageStreamController.add([]);
    }
    String idToken = await user!.getIdToken();
    final response = await http.get(
        Uri.parse(
            '$urlProtocol://$baseUrl/api/room?messageLimit=$messageLimit'),
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

  // A method to submit a command to the server /api/room/:roomId/command
  submitCommand({required String text}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user signed in');
    }

    MessageInput input = MessageInput(text: text);
    final idToken = await user.getIdToken();
    String roomId = _room.id;
    final response = await http.post(
      Uri.parse('$urlProtocol://$baseUrl/api/room/$roomId/command'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(input.toJson()),
    );

    if (response.statusCode == 200) {
      _room = Room.fromJson(jsonDecode(response.body));
      _messageStreamController.add(_room.messages);
    } else {
      throw Exception('Failed to execute command');
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
      Uri.parse('$urlProtocol://$baseUrl/api/room/$roomId/messages'),
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

  Future<void> connectToSocket() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user signed in');
    }
    String idToken = await user.getIdToken();
    print('Attempting to connect to $urlProtocol://$baseUrl');

    IO.Socket socket = IO.io('$urlProtocol://$baseUrl', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.on('connect', (_) {
      print('Connected to the server');
      socket.emit(
          'authenticate', {'token': idToken}); // Send authentication token
    });

    socket.on('disconnect', (_) => print('Disconnected from the server'));

    socket.on('connect_error', (data) => print('Connection error: $data'));

    socket.on('room', (data) {
      _room = Room.fromJson(Map<String, dynamic>.from(data));
      _messageStreamController.add(_room.messages);
    });

    socket.connect();
  }
}
