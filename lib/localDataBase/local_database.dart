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
  static Future<void> saveMessage(String inboxId, String userId, String message) async {
    final db = await database;

    // Normalize inboxId, userId, and message to match server response keys
    inboxId = inboxId.toLowerCase();
    userId = userId.toLowerCase();
    message = message.toLowerCase();

    await db.insert(
      'messages',
      {
        'inboxid': inboxId,
        'userid': userId,
        'message': message,
        // createdat field will be handled by the database, no need to insert it manually
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
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
        'inboxid': message['inboxid'],
        'userid': message['userid'],
        'message': message['message'],
        'createdat': message['createdat'],
      };
    }).toList();
  }

  // Delete all messages for a given inboxId (optional)
  static Future<void> deleteMessages(String inboxId) async {
    final db = await database;
    await db.delete('messages', where: 'inboxid = ?', whereArgs: [inboxId]);
  }
}