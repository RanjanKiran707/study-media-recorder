import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String> getAudioTempPath() async {
  final dir = await getTemporaryDirectory();
  return p.join(
    dir.path,
    'take_${DateTime.now().millisecondsSinceEpoch}.m4a',
  );
}

Future<void> deleteFileIfExists(String path) async {
  final file = File(path);
  if (await file.exists()) {
    await file.delete();
  }
}
