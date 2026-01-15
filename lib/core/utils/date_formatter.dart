import 'package:intl/intl.dart';

/// 日付フォーマットユーティリティ
class DateFormatter {
  DateFormatter._();

  static final DateFormat _fullFormat = DateFormat('yyyy/MM/dd HH:mm');
  static final DateFormat _timeOnly = DateFormat('HH:mm');
  static final DateFormat _dateOnly = DateFormat('MM/dd');

  /// フル日時フォーマット（例: 2024/12/30 07:30）
  static String formatFull(DateTime dateTime) {
    return _fullFormat.format(dateTime.toLocal());
  }

  /// 時刻のみ（例: 07:30）
  static String formatTime(DateTime dateTime) {
    return _timeOnly.format(dateTime.toLocal());
  }

  /// 日付のみ（例: 12/30）
  static String formatDate(DateTime dateTime) {
    return _dateOnly.format(dateTime.toLocal());
  }

  /// 相対時刻（例: 5分前、1時間前）
  static String formatRelative(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'たった今';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}時間前';
    } else {
      return '${difference.inDays}日前';
    }
  }
}
