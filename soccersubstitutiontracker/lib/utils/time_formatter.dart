class TimeFormatter {
  /// Formats seconds to mm:ss (e.g. 125 -> "02:05")
  static String formatMmSs(int totalSeconds) {
    if (totalSeconds < 0) totalSeconds = 0;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Formats seconds to short human text (e.g. "5m 30s" or "12m")
  static String formatShort(int totalSeconds) {
    if (totalSeconds < 0) totalSeconds = 0;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (seconds == 0) return '${minutes}m';
    return '${minutes}m ${seconds}s';
  }
}
