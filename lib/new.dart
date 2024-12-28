import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> listenToSse() async {
  try {
    final uri = Uri.parse('http://your-api-url/message/events');  // Replace with the correct URL
    print("Initiating SSE connection to: $uri"); // Debugging line

    final client = http.Client();
    final request = http.Request('GET', uri);

    final streamedResponse = await client.send(request);

    if (streamedResponse.statusCode == 200 || streamedResponse.statusCode == 201) {
      print("SSE connection established successfully.");
      final eventStream = streamedResponse.stream;

      await for (var chunk in eventStream) {
        String chunkString = utf8.decode(chunk);
        print("Received chunk: $chunkString");  // Debugging line to log each chunk of data

        List<String> events = chunkString.split('\n');
        for (var event in events) {
          if (event.isNotEmpty) {
            try {
              final message = json.decode(event);
              print("Processing event: $message");  // Debugging line to log the parsed message
            } catch (e) {
              print("Error decoding event: $e");
            }
          }
        }
      }
    } else {
      print("Error in SSE connection. Status code: ${streamedResponse.statusCode}");
    }
  } catch (e) {
    print("Error listening to SSE: $e");
  }
}
