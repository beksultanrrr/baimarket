const String mainUrl = 'https://api.iris-cosmetics.kz/';
const String imgUrl = 'https://minio.iris-cosmetics.kz/iris/';

/// Домен Firebase Hosting, который обслуживает публичные ссылки приложения.
///
/// Он же прописан в трёх местах, которые обязаны совпадать, иначе ссылка
/// откроется в браузере вместо приложения:
///   * `android/app/src/main/AndroidManifest.xml` — intent-filter с autoVerify;
///   * `ios/Runner/Runner.entitlements` — associated-domains;
///   * `hosting/public/.well-known/` — assetlinks.json и AASA.
const String shareBaseUrl = 'https://hibai-8a160.web.app';

/// Кастомная схема — запасной путь там, где App Links / Universal Links не
/// работают (WebView внутри мессенджеров). Значение дублируется в
/// AndroidManifest (`android:scheme`) и Info.plist (`CFBundleURLSchemes`).
const String appUrlScheme = 'baimarket';

/// Ссылка из баннера «Пригласить друзей»: корень того же сайта, где лежит
/// страница-заглушка с кнопками на App Store и Google Play.
const String shareAppUrl = shareBaseUrl;

/// Идентификатор Android-**сборки**. Совпадает с `applicationId` в
/// `android/app/build.gradle.kts` и с `package_name` в
/// `hosting/public/.well-known/assetlinks.json`.
const String androidPackageName = 'com.bmarket.baimarket';

/// Пакет, под которым приложение опубликовано в Google Play, — с `ai`, и это
/// **не** [androidPackageName].
///
/// Расхождение историческое и описано в `hosting/README.md` («Расхождение
/// пакетов на Android»); здесь оно продублировано из `public/index.html`, где
/// живёт под тем же именем. Ссылку в магазин собирать можно только отсюда:
/// страница пакета сборки отдаёт 404, и кнопка «Обновить» уводила бы
/// пользователя в пустоту.
///
/// Когда сборочный пакет появится в Play — приравнять к [androidPackageName]
/// здесь и в `index.html` одновременно.
const String playListingId = 'com.baimarket.baimarket';

/// Числовой id карточки в App Store (`apps.apple.com/app/id<ЭТО>`).
/// Берётся из App Store Connect; менять только вместе с
/// `hosting/public/index.html`, где он продублирован для веб-заглушки.
const String appStoreId = '6744940738';

/// Карточка приложения в Google Play (веб-ссылка, работает и без установленного
/// Play — в отличие от `market://`).
const String playStoreUrl =
    'https://play.google.com/store/apps/details?id=$playListingId';

/// Карточка приложения в App Store.
const String appStoreUrl = 'https://apps.apple.com/app/id$appStoreId';

/// Манифест версий: единственный источник правды для проверки обновлений.
///
/// Лежит статикой в том же Firebase Hosting, что и `.well-known/`
/// (`hosting/public/app-version.json`), поэтому выкатывается одной командой
/// `firebase deploy --only hosting` — без релиза приложения и без бэкенда.
/// Почему не парсинг магазинов: у Google Play нет публичного API, а вёрстку
/// страницы Google меняет молча.
/// Подменяется на отладке, чтобы проверить диалог на локальном манифесте:
/// `flutter run --dart-define=UPDATE_MANIFEST_URL=http://10.0.2.2:8080/app-version.json`
/// (для эмулятора Android; на симуляторе iOS — `localhost`).
const String appVersionManifestUrl = String.fromEnvironment(
  'UPDATE_MANIFEST_URL',
  defaultValue: '$shareBaseUrl/app-version.json',
);

/// Публичный Lookup API App Store — запасной источник версии для iOS, если
/// манифест недоступен. Аналога для Google Play не существует.
const String appStoreLookupUrl =
    'https://itunes.apple.com/lookup?bundleId=com.baimarket.baimarket&country=kz';

/// Расчёт стоимости доставки по индексу: `POST` с телом `{ "postalCode": "..." }`.
///
/// Вес корзины считает бэкенд — клиент его не шлёт. Ответ всегда содержит ровно
/// два варианта (BRANCH, DOOR). Лимит — 30 запросов в минуту, поэтому дёргать
/// только по готовому шестизначному индексу и с дебаунсом, а не на каждый символ.
const String deliveryQuoteUrl = '${mainUrl}delivery/quote';

/// Сохранение данных доставки заказа: `POST` — upsert по `cartId`, повторная
/// отправка перезаписывает запись (отдельного `PATCH` не требуется).
const String deliveryUrl = '${mainUrl}delivery';

/// Обновление пары токенов: `POST` с телом `{ "refreshToken": "..." }`.
///
/// Ротации нет — в ответе приходит тот же refresh, перезаписывать его в
/// хранилище не нужно. Каждый успешный вызов продлевает срок жизни на 90 дней.
const String authRefreshUrl = '${mainUrl}auth/refresh';

/// Отзыв refresh-токена при выходе: `POST` с телом `{ "refreshToken": "..." }`.
const String authLogoutUrl = '${mainUrl}auth/logout';

/// Страница отслеживания посылки на сайте Казпочты.
///
/// [trackingNumber] — номер из заказа в формате `AP081184854KZ`.
String kazpostTrackingUrl(String trackingNumber) =>
    'https://post.kz/mail/$trackingNumber';

/// Страница входа в кабинет Satty juldyz. Сюда ведёт пункт «Мои билеты»
/// в профиле вместо внутреннего экрана `/tickets`.
const String sattyJuldyzLoginUrl = 'https://sz.kz/login';
