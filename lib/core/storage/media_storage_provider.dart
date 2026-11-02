export 'media_storage_stub.dart'
    if (dart.library.io) 'media_storage_io.dart'
    if (dart.library.js_interop) 'media_storage_web.dart';
