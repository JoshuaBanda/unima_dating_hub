// services/chat_service.dart
import '/repository/chat_repository.dart';

class ChatService {
  final ChatRepository chatRepository;

  ChatService({required this.chatRepository});

  // Fetch users from the repository
  Future<List<dynamic>> getUsers(String userId) {
    return chatRepository.fetchUsers(userId);
  }

  // Fetch the last message for an inbox
  Future<Map<String, dynamic>> getLastMessage(String inboxId) async {
    return await chatRepository.getLastMessage(inboxId);  // Calling repository method
  }
}
