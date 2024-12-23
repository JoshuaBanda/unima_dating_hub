import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabase {
  static Database? _database;

  // Get the database instance
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  // Initialize the database
  static Future<Database> _initDb() async {
    String path = join(await getDatabasesPath(), 'chat_database.db');
    return await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        inboxid TEXT,
        userid TEXT,
        message TEXT,
        createdat DATETIME DEFAULT CURRENT_TIMESTAMP
      )
      ''');
    });
  }

  // Save a message to the local database (store keys in lowercase to match the server response)
  static Future<void> saveMessage(String inboxId, String userId, String messageText) async {
  final db = await database;

  // Ensure the current timestamp is used for 'createdat'
  final createdAt = DateTime.now().toIso8601String();

  // Log the message being inserted
 // print("Inserting message: inboxId=$inboxId, userId=$userId, message=$messageText, createdAt=$createdAt");

  await db.insert(
    'messages',
    {
      'inboxid': inboxId.toLowerCase(),  // Store inboxid in lowercase for case-insensitivity
      'userid': userId,
      'message': messageText,
      'createdat': createdAt,
    },
    conflictAlgorithm: ConflictAlgorithm.replace,  // Replace if message with same inboxId and userId exists
  );
  
  // After inserting, check if the message is properly stored
  final insertedMessages = await db.query(
    'messages',
    where: 'inboxid = ? COLLATE NOCASE',
    whereArgs: [inboxId.toLowerCase()],
  );
  
 // print("Inserted messages: $insertedMessages");
}

  // Retrieve messages for a given inboxId, ensuring keys match the server response
  static Future<List<Map<String, dynamic>>> getMessages(String inboxId) async {
    final db = await database;

    // Normalize inboxId to lowercase for case-insensitive querying
    inboxId = inboxId.toLowerCase();

    List<Map<String, dynamic>> messages = await db.query(
      'messages',
      where: 'inboxid = ? COLLATE NOCASE',  // Case-insensitive query
      whereArgs: [inboxId],
      orderBy: 'createdat DESC',  // Ensure you are ordering by createdat (timestamp)
    );

    // Ensure keys are lowercase to match server format
    return messages.map((message) {
      return {
        'inboxid': message['inboxid'],
        'userid': message['userid'],
        'message': message['message'],
        'createdat': message['createdat'],
      };
    }).toList();
  }

  static Future<Map<String, dynamic>?> getLastMessage(String inboxId) async {
  try {
    final db = await database;

    // Normalize inboxId to lowercase for case-insensitive querying
    inboxId = inboxId.toLowerCase();

    // Log the inboxId being used
    //print("Fetching last message for inboxId: $inboxId");

    // Query the database for the most recent message, ordered by 'createdat' in descending order
    List<Map<String, dynamic>> messages = await db.query(
      'messages',
      where: 'inboxid = ? COLLATE NOCASE',  // Case-insensitive query
      whereArgs: [inboxId],
      orderBy: 'createdat DESC',  // Ensure you are ordering by createdat (timestamp)
    );

    // Check if messages were fetched successfully
    if (messages.isEmpty) {
      return null;
    }

    // Log the fetched message details
    //print("Last message fetched: ${messages[0]}");

    // Return the last message details as a map
    return {
      'inboxid': messages[0]['inboxid'],
      'userid': messages[0]['userid'],
      'message': messages[0]['message'],
      'createdat': messages[0]['createdat'],
    };
  } catch (e) {
    // Log any errors that occur during the query
    print("Error fetching last message for inboxId: $inboxId - $e");
    return null;
  }
}

  // Delete all messages for a given inboxId (optional)
  static Future<void> deleteMessages(String inboxId) async {
    final db = await database;
    await db.delete('messages', where: 'inboxid = ?', whereArgs: [inboxId]);
  }
}
