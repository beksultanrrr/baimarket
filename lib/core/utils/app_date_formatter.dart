import 'package:flutter/material.dart';

/// Форматирование дат без `intl` — таблицы месяцев для ru/kk/en заданы руками.
///
/// Перенесено из `features/raffle/presentation/utils/raffle_date_formatter.dart`,
/// который теперь делегирует сюда. Пакет `intl` намеренно не добавляется: он не
/// является прямой зависимостью проекта, а нужны всего три формата.
class AppDateFormatter {
  const AppDateFormatter._();

  /// "21 март (19:00)"
  static String formatDrawDate({
    required BuildContext context,
    required String? iso,
  }) {
    final parsed = tryParseLocal(iso);
    if (parsed == null) return '';
    final locale = Localizations.localeOf(context).languageCode;
    final month = _monthShort(locale, parsed.month);
    final hh = parsed.hour.toString().padLeft(2, '0');
    final mm = parsed.minute.toString().padLeft(2, '0');
    return '${parsed.day} $month ($hh:$mm)';
  }

  /// "21 марта" · "21 наурыз" · "21 March"
  ///
  /// Порядок «день месяц» одинаков для всех локалей — так было в
  /// `RaffleDateFormatter`, и менять это здесь нельзя, иначе делегирование
  /// поменяет вид даты на экранах розыгрышей.
  static String formatDayMonth({
    required BuildContext context,
    required String? iso,
  }) {
    final parsed = tryParseLocal(iso);
    if (parsed == null) return '';
    final locale = Localizations.localeOf(context).languageCode;
    final month = _monthFull(locale, parsed.month);
    return '${parsed.day} $month';
  }

  /// "10 февраля 2026 г." · "10 ақпан 2026 ж." · "February 10, 2026"
  ///
  /// Суффикс года («г.» / «ж.») живёт здесь, рядом с таблицами месяцев: это
  /// часть грамматики формата, а не переводимая копирайтинг-строка.
  static String formatDayMonthYear({
    required BuildContext context,
    required String? iso,
  }) {
    final parsed = tryParseLocal(iso);
    if (parsed == null) return '';
    final locale = Localizations.localeOf(context).languageCode;
    final month = _monthFull(locale, parsed.month);
    switch (locale) {
      case 'kk':
        return '${parsed.day} $month ${parsed.year} ж.';
      case 'en':
        return '$month ${parsed.day}, ${parsed.year}';
      case 'ru':
      default:
        return '${parsed.day} $month ${parsed.year} г.';
    }
  }

  static DateTime? tryParseLocal(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    final parsed = DateTime.tryParse(iso);
    return parsed?.toLocal();
  }

  static String _monthShort(String locale, int month) {
    final index = month.clamp(1, 12) - 1;
    switch (locale) {
      case 'kk':
        return _monthsKkShort[index];
      case 'en':
        return _monthsEnShort[index];
      case 'ru':
      default:
        return _monthsRuShort[index];
    }
  }

  static String _monthFull(String locale, int month) {
    final index = month.clamp(1, 12) - 1;
    switch (locale) {
      case 'kk':
        return _monthsKkFull[index];
      case 'en':
        return _monthsEnFull[index];
      case 'ru':
      default:
        return _monthsRuFull[index];
    }
  }

  static const _monthsRuShort = [
    'янв', 'фев', 'март', 'апр', 'май', 'июнь',
    'июль', 'авг', 'сен', 'окт', 'ноя', 'дек',
  ];
  static const _monthsRuFull = [
    'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
    'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
  ];

  static const _monthsKkShort = [
    'қаң', 'ақп', 'нау', 'сәу', 'мам', 'мау',
    'шіл', 'там', 'қыр', 'қаз', 'қар', 'жел',
  ];
  static const _monthsKkFull = [
    'қаңтар', 'ақпан', 'наурыз', 'сәуір', 'мамыр', 'маусым',
    'шілде', 'тамыз', 'қыркүйек', 'қазан', 'қараша', 'желтоқсан',
  ];

  static const _monthsEnShort = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const _monthsEnFull = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
}
