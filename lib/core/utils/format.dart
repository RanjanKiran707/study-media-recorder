/// "1:30" or "1:02:05".
String formatDuration(int milliseconds) {
  final total = Duration(milliseconds: milliseconds).inSeconds;
  final hours = total ~/ 3600;
  final minutes = (total % 3600) ~/ 60;
  final seconds = total % 60;
  final ss = seconds.toString().padLeft(2, '0');
  if (hours > 0) return '$hours:${minutes.toString().padLeft(2, '0')}:$ss';
  return '$minutes:$ss';
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// "Oct 6", or "Oct 6, 2025" when it is not this year.
String formatDate(DateTime date, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final text = '${_months[date.month - 1]} ${date.day}';
  return date.year == today.year ? text : '$text, ${date.year}';
}

/// "02:05", the running timer on the Record screen.
String formatClock(Duration duration) {
  final total = duration.inSeconds;
  final mm = (total ~/ 60).toString().padLeft(2, '0');
  final ss = (total % 60).toString().padLeft(2, '0');
  return '$mm:$ss';
}

/// "4 recordings · 1 subfolder", or "Empty".
String formatCounts({required int subfolders, required int recordings}) {
  final parts = <String>[
    if (recordings > 0)
      '$recordings ${recordings == 1 ? 'recording' : 'recordings'}',
    if (subfolders > 0)
      '$subfolders ${subfolders == 1 ? 'subfolder' : 'subfolders'}',
  ];
  return parts.isEmpty ? 'Empty' : parts.join(' · ');
}
