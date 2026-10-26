/// Флаг блокировки приложения на время процесса.
///
/// `true` — приложение разблокировано в текущем запуске (после ввода PIN или
/// свежего входа по OTP). Живёт только в памяти, поэтому при холодном старте
/// снова `false` — и роутер покажет экран блокировки.
class AppLock {
  static bool _unlocked = false;

  static bool get isUnlocked => _unlocked;

  static void unlock() => _unlocked = true;

  static void lock() => _unlocked = false;
}
