import 'dart:io';

Future<void> deleteHiveTestDirectory(Directory directory) async {
  if (!await directory.exists()) {
    return;
  }

  for (int attempt = 0; attempt < 3; attempt += 1) {
    try {
      await directory.delete(recursive: true);
      return;
    } on FileSystemException catch (error) {
      final int? errorCode = error.osError?.errorCode;
      final bool isWindowsHandleContention =
          Platform.isWindows && (errorCode == 5 || errorCode == 32);
      if (!isWindowsHandleContention) {
        rethrow;
      }
      if (attempt < 2) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }
  }
}
