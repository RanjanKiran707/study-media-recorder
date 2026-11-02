import 'package:web/web.dart' as web;

Future<String> getAudioTempPath() async => '';

Future<void> deleteFileIfExists(String path) async {
  if (path.startsWith('blob:')) {
    try {
      web.URL.revokeObjectURL(path);
    } catch (_) {}
  }
}
