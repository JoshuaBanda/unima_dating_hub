
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket socket;

  void connectSocket(String userId, Function onMessageReceived) {
    socket = IO.io('https://datehubbackend.onrender.com', {
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.on('connect', (_) {
      print('Socket connected: ${socket.id}');
    });

    socket.on('connect_error', (error) {
      print('Socket connection error: $error');
    });

    socket.on('disconnect', (_) {
      print('Socket disconnected');
    });

    socket.on('refresh', (data) {
      onMessageReceived(data);
    });
  }

  void sendMessage(String inboxId, String userId, String messageText) {
    if (socket.connected) {
      socket.emit('triggerRefresh', {'inboxid': inboxId, 'userid': userId, 'message': messageText});
    }
  }

  void disconnect() {
    socket.disconnect();
    socket.dispose();
  }
}
