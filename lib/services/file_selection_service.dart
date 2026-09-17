// lib/services/file_selection_service.dart
//
// File selection without ever loading the picked file into memory.
//
// `file_selector` (the previous implementation) reads the whole file into a
// `byte[]` inside the Android platform channel before handing it to Dart, which
// makes large files crash with OOM. `file_picker` with `withData: false` only
// returns a local path; this service then copies that path with a stream so the
// app owns the lifecycle of the file it is about to encrypt.

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// A file chosen by the user. Only ever holds a path + metadata, never bytes.
class PickedFile {
  final String path;
  final String name;
  final int sizeBytes;

  const PickedFile({
    required this.path,
    required this.name,
    required this.sizeBytes,
  });
}

/// Raw result returned by the platform picker (before staging).
class PickedFileHandle {
  final String path;
  final String name;
  final int sizeBytes;

  const PickedFileHandle({
    required this.path,
    required this.name,
    required this.sizeBytes,
  });
}

/// Thin abstraction over the native picker so it can be faked in tests.
abstract class FilePickerGateway {
  Future<PickedFileHandle?> pickFile();
}

class PlatformFilePickerGateway implements FilePickerGateway {
  const PlatformFilePickerGateway();

  @override
  Future<PickedFileHandle?> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: false,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    final path = file.path;
    if (path == null || path.isEmpty) return null;

    return PickedFileHandle(
      path: path,
      name: file.name,
      sizeBytes: file.size,
    );
  }
}

/// Picks files and stages them into the app's temporary directory using
/// streamed copies (flat memory usage).
class FileSelectionService {
  FileSelectionService({
    FilePickerGateway? gateway,
    Future<Directory> Function()? tempDirectoryProvider,
  })  : _gateway = gateway ?? const PlatformFilePickerGateway(),
        _tempDirectoryProvider = tempDirectoryProvider ?? getTemporaryDirectory;

  final FilePickerGateway _gateway;
  final Future<Directory> Function() _tempDirectoryProvider;

  /// Opens the native picker and stages the chosen file. Returns null if the
  /// user cancelled.
  Future<PickedFile?> pickFile() async {
    final handle = await _gateway.pickFile();
    if (handle == null) return null;
    return stage(handle);
  }

  /// Stream-copies [handle] into a private temp file and logs
  /// `[PICKER] copied N bytes in Xms`.
  Future<PickedFile> stage(PickedFileHandle handle) async {
    final tempDir = await _tempDirectoryProvider();
    final dir = Directory(p.join(tempDir.path, 'ks_picked'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final destination = p.join(
      dir.path,
      '${DateTime.now().microsecondsSinceEpoch}_${_sanitize(handle.name)}',
    );

    final stopwatch = Stopwatch()..start();
    var copied = 0;
    final sink = File(destination).openWrite();
    try {
      await for (final chunk in File(handle.path).openRead()) {
        sink.add(chunk);
        copied += chunk.length;
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
    stopwatch.stop();

    debugPrint(
      '[PICKER] copied $copied bytes in ${stopwatch.elapsedMilliseconds}ms',
    );

    return PickedFile(
      path: destination,
      name: handle.name,
      sizeBytes: copied,
    );
  }

  /// Stages a file that is already on disk (e.g. an `image_picker` capture).
  Future<PickedFile> stageFromPath({
    required String path,
    required String name,
  }) {
    return stage(PickedFileHandle(path: path, name: name, sizeBytes: 0));
  }

  /// Deletes a staged file. Best-effort.
  Future<void> delete(PickedFile? file) async {
    if (file == null) return;
    try {
      final staged = File(file.path);
      if (await staged.exists()) await staged.delete();
    } catch (e) {
      debugPrint('[PICKER] cleanup error: $e');
    }
  }

  static String _sanitize(String name) {
    final cleaned = name.replaceAll(RegExp(r'[^\w.\-]+'), '_');
    return cleaned.isEmpty ? 'file' : cleaned;
  }
}
