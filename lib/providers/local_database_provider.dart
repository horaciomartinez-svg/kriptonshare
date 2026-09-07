import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/telemetry/data/datasources/local_database_datasource.dart';

/// Provider para la base de datos local SQLite.
final localDatabaseProvider = Provider<LocalDatabaseDataSource>((ref) {
  return LocalDatabaseDataSource();
});
