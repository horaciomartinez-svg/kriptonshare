import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptonshare/services/file_selection_service.dart';
import 'package:path/path.dart' as p;

/// Fake gateway: returns a fixed handle without touching any platform channel.
class _FakeGateway implements FilePickerGateway {
  _FakeGateway(this.handle);

  final PickedFileHandle? handle;
  int calls = 0;

  @override
  Future<PickedFileHandle?> pickFile() async {
    calls++;
    return handle;
  }
}

Uint8List _patternBytes(int length) {
  final bytes = Uint8List(length);
  var x = 0x0badc0de;
  for (var i = 0; i < length; i++) {
    x = (1103515245 * x + 12345) & 0x7fffffff;
    bytes[i] = x & 0xff;
  }
  return bytes;
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('ks_picker_test');
  });

  tearDown(() async {
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  FileSelectionService buildService(FilePickerGateway gateway) =>
      FileSelectionService(
        gateway: gateway,
        tempDirectoryProvider: () async => tempDir,
      );

  test('stages a large picked file through a chunked stream copy', () async {
    // Arrange: ~20 MB, far bigger than a single `readAsBytes` allocation would
    // like, and definitely not the intended path.
    const size = 20 * 1024 * 1024;
    final source = File(p.join(tempDir.path, 'big_video.mp4'));
    await source.writeAsBytes(_patternBytes(size), flush: true);
    final gateway = _FakeGateway(
      PickedFileHandle(path: source.path, name: 'big_video.mp4', sizeBytes: size),
    );
    final logs = <String>[];
    final originalDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      logs.add(message ?? '');
    };
    addTearDown(() => debugPrint = originalDebugPrint);

    // Act
    final picked = await buildService(gateway).pickFile();

    // Assert
    expect(gateway.calls, 1);
    expect(picked, isNotNull);
    expect(picked!.name, 'big_video.mp4');
    expect(picked.sizeBytes, size);
    expect(picked.path, isNot(source.path));
    expect(await File(picked.path).readAsBytes(), equals(_patternBytes(size)));
    expect(
      logs.any((line) => line.startsWith('[PICKER] copied $size bytes in ')),
      isTrue,
      reason: 'the chunked copy must log its size and duration',
    );
  });

  test('returns null when the user cancels', () async {
    final picked = await buildService(_FakeGateway(null)).pickFile();
    expect(picked, isNull);
  });

  test('stages an existing on-disk file (camera capture path)', () async {
    // Arrange
    final source = File(p.join(tempDir.path, 'capture.jpg'));
    await source.writeAsBytes(_patternBytes(1024 * 512), flush: true);

    // Act
    final picked = await buildService(_FakeGateway(null)).stageFromPath(
      path: source.path,
      name: 'capture.jpg',
    );

    // Assert
    expect(picked.sizeBytes, 1024 * 512);
    expect(await File(picked.path).readAsBytes(),
        equals(_patternBytes(1024 * 512)));
  });

  test('delete removes the staged file', () async {
    // Arrange
    final source = File(p.join(tempDir.path, 'doc.pdf'));
    await source.writeAsBytes(_patternBytes(4096), flush: true);
    final service = buildService(_FakeGateway(null));
    final picked = await service.stageFromPath(
      path: source.path,
      name: 'doc.pdf',
    );
    expect(await File(picked.path).exists(), isTrue);

    // Act
    await service.delete(picked);

    // Assert
    expect(await File(picked.path).exists(), isFalse);
  });
}
