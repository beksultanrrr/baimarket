import 'app_logger.dart';

/// Тег `LIVE` для socket / стрим-инфраструктуры.
const liveLog = AppLogger('LIVE');

/// Инстанс-обёртка над [liveLog]: `LiveSocketService` и `LiveRoomCubit`
/// принимают логгер в конструкторе, чтобы его можно было подменить в тесте.
class LiveLogger {
  const LiveLogger();
  void info(String message, [Object? data]) => liveLog.info(message, data);
  void warn(String message, [Object? data]) => liveLog.warn(message, data);
  void event(String name, [Object? data]) => liveLog.event(name, data);
  void emit(String name, [Object? data]) => liveLog.emit(name, data);
  void poll(String message, [Object? data]) => liveLog.poll(message, data);
  void connect(String message, [Object? data]) =>
      liveLog.connect(message, data);
  void error(String message, [Object? data, Object? err, StackTrace? st]) =>
      liveLog.error(message, data, err, st);
}
