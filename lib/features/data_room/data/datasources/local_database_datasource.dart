import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// DataSource Local: SQLite Offline-First.
/// Fuente primaria de verdad. Toda escritura pasa aquí primero.
class LocalDatabaseDataSource {
  static const String _dbName = 'kriptonshare_local.db';
  static const int _dbVersion = 2;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createSchema,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createSchema(Database db, int version) async {
    // Tabla local para Data Rooms (retención offline-first)
    await db.execute('''
      CREATE TABLE local_data_rooms (
        id TEXT PRIMARY KEY,
        owner_id TEXT NOT NULL,
        original_filename TEXT NOT NULL,
        file_size_bytes INTEGER NOT NULL,
        status TEXT NOT NULL,
        expires_at TEXT NOT NULL,
        storage_object_key TEXT,
        mime_type TEXT,
        max_downloads INTEGER DEFAULT 5,
        downloads_count INTEGER DEFAULT 0,
        sync_status TEXT DEFAULT 'pending', -- pending, synced, error
        created_at TEXT DEFAULT (datetime('now'))
      )
    ''');

    // Índice para optimizar consultas de tablero (status + expiración)
    await db.execute('''
      CREATE INDEX idx_status_expires ON local_data_rooms(status, expires_at)
    ''');

    // Tabla de cola de sincronización (operaciones pendientes)
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        room_id TEXT NOT NULL,
        operation TEXT NOT NULL, -- create, revoke, delete
        payload TEXT, -- JSON opcional
        created_at TEXT DEFAULT (datetime('now'))
      )
    ''');

    // Tabla de telemetría offline (se sincroniza luego)
    await db.execute('''
      CREATE TABLE local_telemetry (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        link_id TEXT NOT NULL,
        event_type TEXT NOT NULL,
        page_number INTEGER,
        duration_ms INTEGER NOT NULL,
        timestamp_ms INTEGER NOT NULL,
        sync_status TEXT DEFAULT 'pending'
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migración: agregar tabla de cola de sincronización
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sync_queue (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          room_id TEXT NOT NULL,
          operation TEXT NOT NULL,
          payload TEXT,
          created_at TEXT DEFAULT (datetime('now'))
        )
      ''');
    }
  }

  // ─── CRUD Data Rooms ───

  Future<void> insertRoom(Map<String, dynamic> roomData) async {
    final db = await database;
    await db.insert(
      'local_data_rooms',
      roomData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> queryRooms({
    String? status,
    String? ownerId,
    int? limit,
  }) async {
    final db = await database;
    String? where;
    List<Object?>? whereArgs;

    if (status != null && ownerId != null) {
      where = 'status = ? AND owner_id = ?';
      whereArgs = [status, ownerId];
    } else if (status != null) {
      where = 'status = ?';
      whereArgs = [status];
    } else if (ownerId != null) {
      where = 'owner_id = ?';
      whereArgs = [ownerId];
    }

    return await db.query(
      'local_data_rooms',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
      limit: limit,
    );
  }

  Future<Map<String, dynamic>?> getRoomById(String roomId) async {
    final db = await database;
    final results = await db.query(
      'local_data_rooms',
      where: 'id = ?',
      whereArgs: [roomId],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> updateSyncStatus(String roomId, String status) async {
    final db = await database;
    await db.update(
      'local_data_rooms',
      {'sync_status': status},
      where: 'id = ?',
      whereArgs: [roomId],
    );
  }

  Future<void> deleteRoom(String roomId) async {
    final db = await database;
    await db.delete(
      'local_data_rooms',
      where: 'id = ?',
      whereArgs: [roomId],
    );
  }

  Future<void> updateRoomStatus(String roomId, String status) async {
    final db = await database;
    await db.update(
      'local_data_rooms',
      {'status': status},
      where: 'id = ?',
      whereArgs: [roomId],
    );
  }

  // ─── Sync Queue ───

  Future<void> enqueueSyncOperation({
    required String roomId,
    required String operation,
    String? payload,
  }) async {
    final db = await database;
    await db.insert('sync_queue', {
      'room_id': roomId,
      'operation': operation,
      'payload': payload,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingSyncOperations() async {
    final db = await database;
    return await db.query(
      'sync_queue',
      orderBy: 'created_at ASC',
    );
  }

  Future<void> deleteSyncOperation(int id) async {
    final db = await database;
    await db.delete(
      'sync_queue',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAllSyncOperations() async {
    final db = await database;
    await db.delete('sync_queue');
  }

  // ─── Telemetry (offline) ───

  Future<void> insertTelemetry(Map<String, dynamic> telemetry) async {
    final db = await database;
    await db.insert('local_telemetry', telemetry);
  }

  Future<List<Map<String, dynamic>>> getPendingTelemetry() async {
    final db = await database;
    return await db.query(
      'local_telemetry',
      where: 'sync_status = ?',
      whereArgs: ['pending'],
    );
  }

  Future<void> markTelemetrySynced(int id) async {
    final db = await database;
    await db.update(
      'local_telemetry',
      {'sync_status': 'synced'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
