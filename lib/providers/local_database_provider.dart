import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/data_room/data/datasources/local_database_datasource.dart';

/// Provider para la base de datos local SQLite.
final localDatabaseProvider = Provider<LocalDatabaseDataSource>((ref) {
  return LocalDatabaseDataSource();
});
