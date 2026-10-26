import 'package:flutter/material.dart';

/// Единственный на всё приложение ключ [ScaffoldMessenger].
///
/// Вешается на `MaterialApp.router` в `main.dart` и даёт мессенджер, который
/// лежит ВЫШЕ навигатора роутера и всех оверлеев.
///
/// Зачем не `ScaffoldMessenger.of(context)`: оверлей лайв-шопинга поднимает
/// собственный `Scaffold` поверх страницы, и ближайший к экрану мессенджер
/// продолжает держать в своих `_scaffolds` уже деактивированный Scaffold.
/// `showSnackBar` на таком мессенджере падает внутри `_updateScaffolds`
/// («Looking up a deactivated widget's ancestor is unsafe»), причём падает и
/// без async-gap — захват мессенджера заранее здесь не спасает.
final GlobalKey<ScaffoldMessengerState> rootMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Показать снекбар через корневой мессенджер.
///
/// Никогда не бросает: если корневого мессенджера почему-то нет (ключ ещё не
/// смонтирован), пробуем ближайший, а при любой ошибке молча выходим —
/// сообщение об ошибке не имеет права ронять экран.
bool showRootSnackBar(SnackBar snackBar, {BuildContext? fallbackContext}) {
  ScaffoldMessengerState? messenger = rootMessengerKey.currentState;
  if (messenger == null && fallbackContext != null) {
    try {
      messenger = ScaffoldMessenger.maybeOf(fallbackContext);
    } catch (_) {
      messenger = null;
    }
  }
  if (messenger == null) return false;
  try {
    messenger.showSnackBar(snackBar);
    return true;
  } catch (_) {
    return false;
  }
}
