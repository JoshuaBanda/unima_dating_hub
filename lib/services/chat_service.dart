// services/chat_service.dart
import '/repository/chat_repository.dart';

class ChatService {
  final ChatRepository chatRepository;

  ChatService({required this.chatRepository});

  Future<List<dynamic>> getUsers(String userId) {
    return chatRepository.fetchUsers(userId);
  }
}
