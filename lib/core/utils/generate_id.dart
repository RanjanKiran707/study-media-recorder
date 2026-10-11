import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// A new unique id for a folder or a recording.
String generateId() => _uuid.v4();
