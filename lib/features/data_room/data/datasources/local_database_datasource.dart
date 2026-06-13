import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// Fuente de datos local SQLite para KRIPTONSHARE.
/// Soporta Data Rooms, Files, Sync Queue y Telemetry.
class LocalDatabaseDataSource {
  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'kriptonshare.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        // Tabla de Data Rooms
        await db.execute('''
          CREATE TABLE local_data_rooms (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            created_at TEXT NOT NULL,
            expires_at TEXT NOT NULL,
            is_active INTEGER NOT NULL DEFAULT 1,
            owner_id TEXT NOT NULL,
            max_views INTEGER NOT NULL DEFAULT 0,
            current_views INTEGER NOT NULL DEFAULT 0,
            watermark_enabled INTEGER NOT NULL DEFAULT 1,
            download_enabled INTEGER NOT NULL DEFAULT 0,
            allowed_ips TEXT,
            metadata TEXT,
            sync_status TEXT NOT NULL DEFAULT 'pending',
            last_sync_at TEXT,
            created_locally INTEGER NOT NULL DEFAULT 1
          )
        ''');

        // Tabla de Archivos
        await db.execute('''
          CREATE TABLE local_files (
            id TEXT PRIMARY KEY,
            room_id TEXT NOT NULL,
            name TEXT NOT NULL,
            mime_type TEXT NOT NULL,
            size_bytes INTEGER NOT NULL,
            created_at TEXT NOT NULL,
            expires_at TEXT NOT NULL,
            storage_path TEXT NOT NULL,
            owner_id TEXT NOT NULL,
            is_encrypted INTEGER NOT NULL DEFAULT 1,
            encryption_key_id TEXT,
            metadata TEXT,
            sync_status TEXT NOT NULL DEFAULT 'pending',
            FOREIGN KEY (room_id) REFERENCES local_data_rooms(id) ON DELETE CASCADE
          )
        ''');

        // Tabla de Cola de Sincronización
        await db.execute('''
          CREATE TABLE sync_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            operation_type TEXT NOT NULL,
            table_name TEXT NOT NULL,
            record_id TEXT NOT NULL,
            payload TEXT NOT NULL,
            created_at TEXT NOT NULL,
            retry_count INTEGER NOT NULL DEFAULT 0,
            last_attempt_at TEXT,
            status TEXT NOT NULL DEFAULT 'pending'
          )
        ''');

        // Tabla de Eventos de Telemetría
        await db.execute('''
          CREATE TABLE local_telemetry (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            link_id TEXT NOT NULL,
            event_type TEXT NOT NULL,
            page_number INTEGER,
            duration_ms INTEGER NOT NULL,
            timestamp_ms INTEGER NOT NULL,
            ip_address TEXT,
            user_agent TEXT,
            geolocation TEXT,
            sync_status TEXT NOT NULL DEFAULT 'pending'
          )
        ''');

        // Índices
        await db.execute('CREATE INDEX idx_rooms_owner ON local_data_rooms(owner_id)');
        await db.execute('CREATE INDEX idx_rooms_expires ON local_data_rooms(expires_at)');
        await db.execute('CREATE INDEX idx_files_room ON local_files(room_id)');
        await db.execute('CREATE INDEX idx_sync_queue_status ON sync_queue(status)');
        await db.execute('CREATE INDEX idx_telemetry_link ON local_telemetry(link_id)');
      },
    );
  }

  // ─── Data Rooms (métodos que usan los repositorios) ───

  Future<void> insertRoom(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('local_data_rooms', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> queryRooms() async {
    final db = await database;
    return await db.query('local_data_rooms', orderBy: 'created_at DESC');
  }

  Future<Map<String, dynamic>?> getRoomById(String id) async {
    final db = await database;
    final maps = await db.query('local_data_rooms', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return maps.first;
  }

  Future<void> updateRoomStatus(String id, String status) async {
    final db = await database;
    await db.update(
      'local_data_rooms',
      {'status': status, 'sync_status': 'pending'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateSyncStatus(String id, String syncStatus) async {
    final db = await database;
    await db.update(
      'local_data_rooms',
      {'sync_status': syncStatus, 'last_sync_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteRoom(String id) async {
    final db = await database;
    await db.delete('local_data_rooms', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Files ───

  Future<void> insertFile(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('local_files', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getFilesByRoomId(String roomId) async {
    final db = await database;
    return await db.query('local_files', where: 'room_id = ?', whereArgs: [roomId]);
  }

  // ─── Sync Queue ───

  Future<void> enqueueSyncOperation({
    required String roomId,
    required String operation,
    String? payload,
  }) async {
    final db = await database;
    await db.insert('sync_queue', {
      'operation_type': operation,
      'table_name': 'local_data_rooms',
      'record_id': roomId,
      'payload': payload ?? '',
      'created_at': DateTime.now().toIso8601String(),
      'status': 'pending',
    });
  }

  Future<List<Map<String, dynamic>>> getPendingSyncOperations() async {
    final db = await database;
    return await db.query(
      'sync_queue',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'created_at ASC',
    );
  }

  Future<void> deleteSyncOperation(int id) async {
    final db = await database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> incrementRetryCount(int id) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE sync_queue SET retry_count = retry_count + 1, last_attempt_at = ? WHERE id = ?',
      [DateTime.now().toIso8601String(), id],
    );
  }

  // ─── Telemetry ───

  Future<void> insertTelemetry(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('local_telemetry', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getPendingTelemetry() async {
    final db = await database;
    return await db.query(
      'local_telemetry',
      where: 'sync_status = ?',
      whereArgs: ['pending'],
      orderBy: 'timestamp_ms ASC',
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

  // ─── General ───

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
