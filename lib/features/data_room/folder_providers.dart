import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data/repositories/folder_repository_impl.dart';
import 'domain/repositories/i_folder_repository.dart';

final folderRepositoryProvider = Provider<IFolderRepository>((ref) {
  return FolderRepositoryImpl(Supabase.instance.client);
});
