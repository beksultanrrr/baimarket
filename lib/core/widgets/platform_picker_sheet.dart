import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'choice_sheet.dart';

bool get _isIos => !kIsWeb && Platform.isIOS;

/// Выбор одного элемента из списка (регион, город, филиал).
///
/// Раньше на iOS показывался отдельный Cupertino-попап, а на Android —
/// свой Material-шит; выглядели они по-разному, и Cupertino-вариант рисовал
/// заголовок вне `Material` — оттуда бралось жёлтое двойное подчёркивание, а
/// галочку он брал из шрифта, где её нет (получался «?»). Теперь на обеих
/// платформах открывается общий [showChoiceSheet].
Future<T?> showPlatformItemPicker<T>({
  required BuildContext context,
  required String title,
  required List<T> items,
  required String Function(T) itemLabel,
  T? selected,
  bool Function(T a, T b)? equals,
}) {
  return showChoiceSheet<T>(
    context: context,
    title: title,
    items: items,
    labelOf: itemLabel,
    selected: selected,
    equals: equals,
  );
}

Widget platformActivityIndicator({Color? color}) {
  return _isIos
      ? CupertinoActivityIndicator(color: color)
      : Center(child: CircularProgressIndicator(color: color));
}
