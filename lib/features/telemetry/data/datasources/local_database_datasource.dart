import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// Fuente de datos local SQLite para KRIPTONSHARE.
/// Mantiene la cola offline de eventos de telemetría de visualización.
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

        // Índice
        await db.execute('CREATE INDEX idx_telemetry_link ON local_telemetry(link_id)');
      },
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
