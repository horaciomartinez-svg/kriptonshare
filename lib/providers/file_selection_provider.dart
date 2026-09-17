// lib/providers/file_selection_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/file_selection_service.dart';

/// File picker + streamed staging service. Overridable in tests so the
/// selection flow can be exercised without a platform channel.
final fileSelectionServiceProvider =
    Provider<FileSelectionService>((ref) => FileSelectionService());
