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

/// "11 Oct 2026".
String formatDate(DateTime date) =>
    '${date.day} ${_months[date.month - 1]} ${date.year}';

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
