import 'dart:math' as math;

import 'package:flutter/material.dart';

String formatClock(Duration duration) {
  final total = duration.inSeconds;
  final negative = total < 0;
  final seconds = total.abs();
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  final body = h > 0
      ? '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
      : '$m:${s.toString().padLeft(2, '0')}';
  return negative ? '-$body' : body;
}

String formatRuntime(int? minutes) {
  if (minutes == null || minutes <= 0) return '';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '$m 分钟';
  if (m == 0) return '$h 小时';
  return '$h 小时 $m 分';
}

String formatFileSize(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  final i = (math.log(bytes) / math.log(1024)).floor().clamp(
    0,
    units.length - 1,
  );
  final value = bytes / math.pow(1024, i);
  return '${value.toStringAsFixed(i == 0 ? 0 : 1)} ${units[i]}';
}

String formatYear(int? year) => year == null ? '' : '$year';

String episodeCode(int? season, int? episode) {
  if (season == null && episode == null) return '';
  final s = (season ?? 1).toString().padLeft(2, '0');
  final e = (episode ?? 0).toString().padLeft(2, '0');
  return 'S${s}E$e';
}

String episodeLabel(int? season, int? episode) {
  if (season == null && episode == null) return '';
  return '第 ${season ?? 1} 季 · 第 ${episode ?? 0} 集';
}

String formatDate(String? isoDate) {
  if (isoDate == null || isoDate.isEmpty) return '';
  final parsed = DateTime.tryParse(isoDate);
  if (parsed == null) return isoDate;
  return '${parsed.year}/${parsed.month.toString().padLeft(2, '0')}/${parsed.day.toString().padLeft(2, '0')}';
}

String formatRating(double? rating) {
  if (rating == null || rating <= 0) return '';
  return rating.toStringAsFixed(1);
}

String formatProgressFraction(double fraction) {
  final percent = (fraction * 100).round().clamp(0, 100);
  return '$percent%';
}

/// A stable, human-readable key for grouping episodes that have not been
/// matched against TMDB yet.
String seriesKeyFromTitle(String title, {int? year}) {
  final normalized = title
      .toLowerCase()
      .replaceAll(RegExp(r'[^0-9a-zA-Z\u4e00-\u9fff]+'), '')
      .trim();
  final suffix = year == null ? '' : ':$year';
  return 'name:$normalized$suffix';
}

/// Deterministic gradient used as the fallback artwork for an item.
/// Keeping it deterministic means the same film always has the same colour.
List<int> fallbackGradient(String seed) {
  var hash = 0;
  for (final code in seed.codeUnits) {
    hash = (hash * 31 + code) & 0x7fffffff;
  }
  final hue = (hash % 360).toDouble();
  final base = HSLColor.fromAHSL(1, hue, 0.16, 0.16).toColor();
  final top = HSLColor.fromAHSL(1, (hue + 24) % 360, 0.20, 0.24).toColor();
  return [base.toARGB32(), top.toARGB32()];
}

String initials(String title) {
  final trimmed = title.trim();
  if (trimmed.isEmpty) return '?';
  final chars = trimmed.runes.toList();
  if (chars.length == 1) return String.fromCharCode(chars.first).toUpperCase();
  // CJK titles read better with their first two characters.
  final first = chars.first;
  if (first >= 0x4e00 && first <= 0x9fff) {
    return String.fromCharCodes(chars.take(2));
  }
  final words = trimmed
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  if (words.length >= 2) {
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }
  return trimmed.substring(0, math.min(2, trimmed.length)).toUpperCase();
}

String cleanError(Object error) {
  final text = error.toString();
  if (text.length <= 180) return text;
  return '${text.substring(0, 177)}...';
}
