import 'package:dio/dio.dart';

import '../routing/app_routing.dart';
import '../secure_token_storage.dart';
import '../urls.dart';
import '../../features/live/presentation/widgets/live_shopping_scope.dart';
import '../services/app_logger.dart';

/// Single Dio instance for all authenticated HTTP traffic.
///
/// Behavior:
/// 1. Adds `Authorization: Bearer <token>` to every request when a token exists.
/// 2. If no token exists, the request is rejected locally as a 401 — no
///    network call is made. The flag `extra['hadAuth']` stays false.
/// 3. На настоящий 401 от сервера (access-токен протух) сначала идёт
///    `POST /auth/refresh`, и при успехе исходный запрос повторяется со свежим
///    токеном — пользователь ничего не замечает. Разлогин остался только на
///    случай, когда рефреш не удался или refresh-токена нет вовсе. Ветка
///    по-прежнему гейтится на `extra['hadAuth'] == true`, так что гостя 401
///    никуда не выкидывает.
/// 4. На 429 запрос один раз тихо повторяется через паузу из заголовка
///    `Retry-After` (в СЕКУНДАХ). Нужно ради `/delivery/quote` — там лимит
///    30 запросов в минуту.
/// 5. Каждый запрос/ответ пишется через `netLog` (тег `NET`) с методом,
///    путём, статусом и временем. При нужде в payload-ах — поднять
///    [logBodies] до `true`.
final Dio appDio = _build(requireAuth: true);

/// Тот же интерсептор, но для ручек с **опциональной** авторизацией.
///
/// Отличие от [appDio] одно: при отсутствии токена запрос НЕ реджектится
/// локально, а уходит в сеть как гостевой. Нужно там, где бэк отдаёт данные
/// и без токена, но с токеном обогащает ответ (`isInFavorite`, `cartQuantity`,
/// `hasActivePlus`): `GET /seller`, `GET /seller/:id/models`, `GET /model/:id`,
/// `GET /model/:id/reviews`.
///
/// Рефреш и авто-логаут на 401 сюда не распространяются: ветка в `onError`
/// гейтится на `extra['hadAuth'] == true`, поэтому гость, получивший 401, не
/// будет разлогинен.
final Dio optionalAuthDio = _build(requireAuth: false);

const _hadAuthKey = 'hadAuth';
const _startTimeKey = 'reqStartMs';

/// Метки повторов в `options.extra`. Без них рефреш и 429 зациклились бы:
/// повтор снова получил бы тот же код и снова полез бы повторяться.
const _refreshedKey = 'retriedAfterRefresh';
const _throttledKey = 'retriedAfter429';

/// Таймауты на весь трафик приложения. До этого их не было вовсе — упавшее
/// соединение держало спиннер бесконечно. `/delivery/quote` ходит на сторону
/// (Казпочта), поэтому на приём даём с запасом.
const Duration _connectTimeout = Duration(seconds: 20);
const Duration _receiveTimeout = Duration(seconds: 30);
const Duration _sendTimeout = Duration(seconds: 30);

/// Пауза перед повтором 429, когда сервер не прислал `Retry-After`.
const Duration _defaultRetryAfter = Duration(seconds: 3);

/// Чистый клиент **без интерсептора** — только под `POST /auth/refresh`.
///
/// Через [appDio] рефреш звать нельзя: его же `onError` поймал бы 401 самого
/// рефреша и ушёл бы в бесконечную рекурсию.
final Dio _refreshDio = Dio(
  BaseOptions(
    connectTimeout: _connectTimeout,
    receiveTimeout: _receiveTimeout,
    sendTimeout: _sendTimeout,
  ),
);

/// Единственный «полёт» рефреша на все параллельные 401.
///
/// Ротации у бэкенда нет, так что повторный рефреш и не сломал бы ничего, но
/// пачка одинаковых запросов при веере параллельных 401 сети ни к чему.
Future<bool>? _refreshInFlight;

/// Если включить — успешные response пишутся вместе с телом (truncated).
/// Полезно при глубокой отладке, выключено по умолчанию чтобы не флудить.
const bool logBodies = false;

Dio _build({required bool requireAuth}) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: _connectTimeout,
      receiveTimeout: _receiveTimeout,
      sendTimeout: _sendTimeout,
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        options.extra[_startTimeKey] = DateTime.now().millisecondsSinceEpoch;
        final token = await getAuthToken();
        if (token != null) {
          options.headers['authorization'] = 'Bearer $token';
          options.extra[_hadAuthKey] = true;
          netLog.api(
            '→ ${options.method} ${options.uri.path}',
            'auth=yes',
          );
          return handler.next(options);
        }
        options.extra[_hadAuthKey] = false;
        if (!requireAuth) {
          netLog.api(
            '→ ${options.method} ${options.uri.path}',
            'auth=no',
          );
          return handler.next(options);
        }
        netLog.warn(
          'rejected locally — no token',
          '${options.method} ${options.uri.path}',
        );
        return handler.reject(
          DioException(
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: 401,
              data: {'error': 'no auth token'},
            ),
            type: DioExceptionType.cancel,
            error: 'no auth token',
          ),
          true,
        );
      },
      onResponse: (response, handler) {
        final dt = _elapsedMs(response.requestOptions);
        final tail = logBodies && response.data != null
            ? '${dt}ms · ${response.data}'
            : '${dt}ms';
        netLog.api(
          '← ${response.statusCode} ${response.requestOptions.method} '
              '${response.requestOptions.uri.path}',
          tail,
        );
        return handler.next(response);
      },
      onError: (e, handler) async {
        final dt = _elapsedMs(e.requestOptions);
        final hadAuth = e.requestOptions.extra[_hadAuthKey] == true;
        final code = e.response?.statusCode;
        netLog.warn(
          '← ${code ?? '-'} ${e.requestOptions.method} '
              '${e.requestOptions.uri.path}',
          '${dt}ms · ${e.response?.data ?? e.message}',
        );

        // Протух access-токен: пробуем обменять refresh и повторить запрос.
        // `_refreshedKey` уже стоит, если это и есть повтор — второй раз в
        // рефреш не идём.
        if (code == 401 &&
            hadAuth &&
            e.requestOptions.extra[_refreshedKey] != true) {
          final refreshed = await _refreshAccessToken();
          if (refreshed) {
            netLog.step(
              'token refreshed → retry ${e.requestOptions.method} '
                  '${e.requestOptions.uri.path}',
            );
            try {
              final response = await _retry(
                dio,
                e.requestOptions,
                _refreshedKey,
              );
              return handler.resolve(response);
            } on DioException catch (retryError) {
              // Свежий токен и снова 401 — сессию уже не спасти.
              if (retryError.response?.statusCode == 401) {
                await _signOut('401 даже со свежим токеном');
              }
              return handler.next(retryError);
            }
          }
          await _signOut('рефреш не удался');
          return handler.next(e);
        }

        // Лимит запросов (30/мин на `/delivery/quote`): ждём столько, сколько
        // просит сервер, и один раз тихо повторяем.
        if (code == 429 && e.requestOptions.extra[_throttledKey] != true) {
          final delay = _retryAfterDelay(e.response);
          netLog.warn(
            '429 → retry through ${delay.inSeconds}s',
            '${e.requestOptions.method} ${e.requestOptions.uri.path}',
          );
          await Future.delayed(delay);
          try {
            final response = await _retry(dio, e.requestOptions, _throttledKey);
            return handler.resolve(response);
          } on DioException catch (retryError) {
            return handler.next(retryError);
          }
        }

        return handler.next(e);
      },
    ),
  );
  return dio;
}

/// Обмен refresh-токена на новый access: `POST /auth/refresh` с телом
/// `{ "refreshToken": "..." }`.
///
/// Ротации нет — в ответе приходит тот же refresh, поэтому в хранилище
/// перезаписываем только access. Возвращает `false`, если refresh-токена нет
/// (старая установка, где сохранялся только access) или бэкенд отказал —
/// вызывающая сторона тогда разлогинивает.
Future<bool> _refreshAccessToken() {
  return _refreshInFlight ??= _doRefresh().whenComplete(() {
    _refreshInFlight = null;
  });
}

Future<bool> _doRefresh() async {
  final refreshToken = await getRefreshToken();
  if (refreshToken == null || refreshToken.isEmpty) {
    netLog.warn('refresh skipped — нет refresh-токена');
    return false;
  }
  try {
    final response = await _refreshDio.post(
      authRefreshUrl,
      data: {'refreshToken': refreshToken},
    );
    final data = response.data;
    final accessToken = data is Map ? data['accessToken'] as String? : null;
    if (accessToken == null || accessToken.isEmpty) {
      netLog.warn('refresh без accessToken в ответе', data);
      return false;
    }
    await setAuthToken(accessToken);
    netLog.api('← ${response.statusCode} POST /auth/refresh', 'ok');
    return true;
  } on DioException catch (e) {
    netLog.warn(
      'refresh failed',
      '${e.response?.statusCode ?? '-'} · ${e.response?.data ?? e.message}',
    );
    return false;
  } catch (e) {
    netLog.warn('refresh failed', e.toString());
    return false;
  }
}

/// Повтор исходного запроса тем же клиентом.
///
/// `fetch` прогоняет запрос через интерсептор заново, поэтому свежий токен
/// подставится сам в `onRequest`. [flag] переживает повтор в `extra` и не даёт
/// уйти в цикл.
Future<Response<dynamic>> _retry(Dio dio, RequestOptions options, String flag) {
  options.extra[flag] = true;
  final data = options.data;
  // FormData — одноразовый поток, второй раз его не прочитать (аватар).
  if (data is FormData) {
    options.data = data.clone();
  }
  return dio.fetch(options);
}

/// Полный разлогин: стираем обе половины пары токенов и уводим на `/auth`.
Future<void> _signOut(String reason) async {
  netLog.warn('sign-out', reason);
  await clearTokens();
  try {
    // Сначала разбираем стек шитов эфира: router.go подменяет только
    // нижний стек go_router, и без этого корзина с оформлением
    // остались бы висеть поверх экрана авторизации.
    closeLiveSheetsFrom(appRouteObserver.navigatorContext);
    router.go('/auth');
  } catch (_) {
    // router not yet attached — ignore
  }
}

/// `Retry-After` приходит в СЕКУНДАХ. Заголовка может не быть — тогда берём
/// дефолт; верхнюю границу режем, ждать дольше минуты бессмысленно.
Duration _retryAfterDelay(Response<dynamic>? response) {
  final raw = response?.headers.value('retry-after');
  final seconds = int.tryParse(raw?.trim() ?? '');
  if (seconds == null || seconds <= 0) return _defaultRetryAfter;
  return Duration(seconds: seconds.clamp(1, 60));
}

int _elapsedMs(RequestOptions options) {
  final start = options.extra[_startTimeKey];
  if (start is int) {
    return DateTime.now().millisecondsSinceEpoch - start;
  }
  return -1;
}
