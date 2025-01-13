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
    return await openDatabase(path, version: 2, onCreate: (db, version) async {
      await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        messageid TEXT,  -- New column for remote message ID
        inboxid TEXT,
        userid TEXT,
        message TEXT,
        status TEXT DEFAULT 'sent',  -- Column for message status (optional)
        createdat DATETIME DEFAULT CURRENT_TIMESTAMP
      )
      ''');
    }, onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 2) {
        await db.execute('''
        ALTER TABLE messages ADD COLUMN messageid TEXT
        ''');
      }
    });
  }

  // Save a message to the local database (store keys in lowercase to match the server response)
  static Future<void> saveMessage(
  String inboxId, 
  String userId, 
  String messageText, 
  String messageId, 
  String createdAt, // Add createdAt as a parameter
  {String status = 'sent'} // status is still optional with default 'sent'
) async {
  final db = await database;

  // Log the message being inserted
  // print("Inserting message: inboxId=$inboxId, userId=$userId, message=$messageText, status=$status, createdAt=$createdAt");

  await db.insert(
    'messages',
    {
      'messageid': messageId,  // Store messageid from the remote server
      'inboxid': inboxId.toLowerCase(),  // Store inboxid in lowercase for case-insensitivity
      'userid': userId,
      'message': messageText,
      'status': status,  // Include the status field
      'createdat': createdAt,  // Use the provided createdAt timestamp
    },
    conflictAlgorithm: ConflictAlgorithm.replace,  // Replace if message with the same messageId exists
  );
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
        'id': message['id'],  // Local database ID (auto-increment)
        'messageid': message['messageid'],  // Remote message ID
        'inboxid': message['inboxid'],
        'userid': message['userid'],
        'message': message['message'],
        'status': message['status'],  // Include status in the response
        'createdat': message['createdat'],
      };
    }).toList();
  }

  static Future<Map<String, dynamic>?> getLastMessage(String inboxId) async {
    try {
      final db = await database;

      // Normalize inboxId to lowercase for case-insensitive querying
      inboxId = inboxId.toLowerCase();

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

      return {
        'id': messages[0]['id'],  // Local database ID (auto-increment)
        'messageid': messages[0]['messageid'],  // Remote message ID
        'inboxid': messages[0]['inboxid'],
        'userid': messages[0]['userid'],
        'message': messages[0]['message'],
        'status': messages[0]['status'],  // Include status
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

    // Update message status
  static Future<void> updateMessageStatus(String messageId, String newStatus) async {
    final db = await database;

    // Update the status of the message with the given messageId
    await db.update(
      'messages',
      {'status': newStatus},  // New status
      where: 'messageid = ?',  // Specify the messageId as a filter
      whereArgs: [messageId],  // Provide the messageId
    );

    print("Message status updated for messageId: $messageId to status: $newStatus");
  }




  // Get message by its unique messageId
static Future<Map<String, dynamic>?> getMessageById(String messageId) async {
  try {
    final db = await database;

    // Query the database for the message with the specific messageId
    List<Map<String, dynamic>> messages = await db.query(
      'messages',
      where: 'messageid = ?',  // Filter by messageId
      whereArgs: [messageId],  // Provide the messageId as an argument
    );

    // Check if any message was found
    if (messages.isEmpty) {
      return null;  // Return null if no message is found with the provided messageId
    }

    return {
      'id': messages[0]['id'],  // Local database ID (auto-increment)
      'messageid': messages[0]['messageid'],  // Remote message ID
      'inboxid': messages[0]['inboxid'],
      'userid': messages[0]['userid'],
      'message': messages[0]['message'],
      'status': messages[0]['status'],  // Include status
      'createdat': messages[0]['createdat'],
    };
  } catch (e) {
    // Log any errors that occur during the query
    print("Error fetching message with messageId: $messageId - $e");
    return null;
  }
}

}
