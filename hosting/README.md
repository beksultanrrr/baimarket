# Ссылки на товары (Firebase Hosting)

Сайт на Firebase Hosting, из-за которого ссылка вида
`https://hibai-8a160.web.app/product/42` открывает карточку товара прямо
в приложении.

Firebase Dynamic Links выключены Google 25 августа 2025 года, поэтому механика
собрана вручную из двух стандартных технологий: **Android App Links** и
**iOS Universal Links**. Hosting здесь нужен ровно для двух вещей — отдать
файлы верификации из `.well-known/` и показать страницу-заглушку тем, у кого
приложение не установлено.

## Что где лежит

| Файл | Зачем |
| --- | --- |
| `public/.well-known/assetlinks.json` | Android проверяет, что домен разрешил приложению перехватывать свои ссылки |
| `public/.well-known/apple-app-site-association` | То же самое для iOS |
| `public/index.html` | Заглушка: кнопка «Открыть в приложении» + ссылки на магазины |
| `../firebase.json` | Раздел `hosting`: заголовки, rewrites, `ignore` |

Клиентская часть:

| Файл | Зачем |
| --- | --- |
| `lib/core/urls.dart` | `shareBaseUrl`, `appUrlScheme` — единственный источник домена |
| `lib/core/services/share_links.dart` | Сборка ссылок для «Поделиться» |
| `lib/core/routing/deep_link_parser.dart` | Разбор входящей ссылки в маршрут |
| `android/app/src/main/AndroidManifest.xml` | intent-filter + `flutter_deeplinking_enabled` |
| `ios/Runner/Runner.entitlements` | `com.apple.developer.associated-domains` |
| `ios/Runner/Info.plist` | `FlutterDeepLinkingEnabled`, `CFBundleURLTypes` |

Домен упоминается в пяти файлах. При смене домена меняются **все пять**, иначе
ссылка молча начнёт открываться в браузере вместо приложения.

## Деплой

```bash
firebase login                       # один раз
firebase deploy --only hosting       # проект hibai-8a160 берётся из .firebaserc
```

Локальная проверка без публикации:

```bash
firebase emulators:start --only hosting
curl -i http://127.0.0.1:5000/.well-known/apple-app-site-association
```

> В `firebase.json` намеренно переопределён `ignore`: значение по умолчанию
> содержит `**/.*` и вырезало бы всю папку `.well-known` из деплоя. Симптом —
> файлы есть в репозитории, но отдают 404, и верификация не проходит нигде.

## Обязательный шаг перед релизом: отпечаток подписи Android

`public/.well-known/assetlinks.json` сейчас содержит **только debug-отпечаток**
машины разработчика. Этого хватает, чтобы проверить механику на `flutter run`,
но App Links **не заработают в релизной сборке**, пока в файл не добавлен
отпечаток ключа, которым подписан APK в Google Play.

1. Play Console → приложение → **Test and release → Setup → App signing**.
2. Скопировать **SHA-256 certificate fingerprint** из блока
   *App signing key certificate*. Если включена загрузка через upload-ключ,
   добавить и **Upload key certificate** — оба.
3. Дописать значения в массив `sha256_cert_fingerprints`:

```json
"sha256_cert_fingerprints": [
  "A5:55:...:A8",
  "<SHA-256 из App signing key certificate>",
  "<SHA-256 из Upload key certificate>"
]
```

4. `firebase deploy --only hosting`.

Отпечаток локального debug-ключа, если понадобится на другой машине:

```bash
keytool -list -v -keystore ~/.android/debug.keystore \
  -alias androiddebugkey -storepass android -keypass android | grep SHA256
```

Отпечаток релизного ключа из `android/key.properties`:

```bash
keytool -list -v -keystore android/upload-keystore.jks -alias <keyAlias> | grep SHA256
```

## Обязательный шаг перед релизом: Associated Domains на iOS

Возможность **Associated Domains** должна быть включена для App ID
`com.baimarket.baimarket` в Apple Developer Portal (Certificates, Identifiers &
Profiles → Identifiers), после чего профили подписи нужно перегенерировать.
Без этого сборка упадёт на этапе подписи с жалобой на entitlement.

## Проверка

Android (приложение установлено):

```bash
adb shell am start -a android.intent.action.VIEW \
  -d "https://hibai-8a160.web.app/product/42"

# статус верификации App Links
adb shell pm get-app-links com.bmarket.baimarket
# ожидается: hibai-8a160.web.app: verified
```

Запасная схема (работает всегда, верификации не требует):

```bash
adb shell am start -a android.intent.action.VIEW -d "baimarket:///product/42"
```

iOS (симулятор):

```bash
xcrun simctl openurl booted "https://hibai-8a160.web.app/product/42"
xcrun simctl openurl booted "baimarket:///product/42"
```

Universal Links не срабатывают, если ссылку вставить прямо в адресную строку
Safari — это поведение самой iOS. Проверять надо переходом по ссылке из
заметок, сообщения или письма.

Валидаторы:

* Android — https://developers.google.com/digital-asset-links/tools/generator
* iOS — https://app-site-association.cdn-apple.com/a/v1/hibai-8a160.web.app
  (кэш Apple CDN обновляется до 24 часов после деплоя)

## Расхождение пакетов на Android

Сборка идёт под `com.bmarket.baimarket` (так она зарегистрирована в Firebase),
а в Google Play опубликован **другой** пакет — `com.baimarket.baimarket`, с
`ai`. Ссылка на пакет сборки отдаёт 404.

Поэтому в `public/index.html` два разных значения:

* `androidPackage` = `com.bmarket.baimarket` — им адресуется `intent://`, он же
  стоит в `assetlinks.json`;
* `playListingId` = `com.baimarket.baimarket` — только для кнопки «установить»,
  чтобы она вела на существующую страницу.

Следствие, о котором надо помнить: **приложение, установленное из Play прямо
сейчас, ссылки принимать не будет** — это другой пакет, и `assetlinks.json` его
не объявляет. Ссылки работают только на сборках `com.bmarket.baimarket`.

Когда `com.bmarket.baimarket` появится в Play, приравняйте `playListingId` к
`androidPackage` — расхождение исчезнет.

## Манифест версий: `public/app-version.json`

Тот же Hosting раздаёт единственный источник правды для проверки обновлений в
приложении. Бэкенд не нужен: файл статический, выкатывается тем же
`firebase deploy --only hosting`, без релиза в магазины.

```json
{
  "android": {
    "latestVersion": "1.1.0",
    "minSupportedVersion": "1.0.0",
    "storeUrl": "https://play.google.com/store/apps/details?id=com.baimarket.baimarket",
    "releaseNotes": { "ru": "…", "en": "…", "kk": "…" }
  },
  "ios": { "…": "то же самое, но storeUrl на App Store" }
}
```

| Поле | Обязательно | Что делает |
| --- | --- | --- |
| `latestVersion` | да | Версия, с которой сравнивается установленная сборка |
| `minSupportedVersion` | нет | Пол поддерживаемых версий: всё, что ниже, блокируется независимо от разрядов |
| `storeUrl` | нет | Куда ведёт кнопка «Обновить». Без него берётся ссылка из `lib/core/urls.dart` |
| `releaseNotes` | нет | Блок «Что нового» по кодам локалей. Можно строкой — тогда общий текст для всех |

Правило срочности зашито в приложении (`AppUpdateInfo.severityFor`) и сравнивает
разряды установленной версии с `latestVersion`:

| Что разошлось | Пример | Что видит пользователь |
| --- | --- | --- |
| MAJOR | `1.0.7` → `2.0.0` | Диалог без выхода: ни «Позже», ни тапа мимо |
| MINOR | `1.0.7` → `1.1.0` | Диалог с «Позже» — молчит сутки по этой версии |
| PATCH | `1.0.7` → `1.0.8` | Ничего |

`minSupportedVersion` бьёт это правило: им блокируют и патч-версию, если в ней
критичный баг, не выпуская ради этого мажор.

Порядок выкатки обязательного обновления: сначала релиз доезжает до магазинов,
и только потом в манифесте поднимается `latestVersion`. Наоборот — значит
запереть пользователей в диалоге, который ведёт на ещё не опубликованную сборку.

`firebase.json` отдаёт этот файл с `no-cache`, а клиент добавляет к запросу
`?ts=<millis>` — иначе обязательное обновление доехало бы до людей через час
после деплоя.

> Пока файл не задеплоен, Hosting из-за `rewrites: ** → /index.html` отдаёт на
> этот путь HTML со статусом 200. Клиент такое не парсит и просто считает, что
> источника нет: на Android диалог не покажется вовсе, на iOS сработает запасной
> App Store Lookup. Проверить после деплоя:
> `curl -i https://hibai-8a160.web.app/app-version.json` — `content-type` должен
> быть `application/json`.

## Чего пока нет: превью ссылки

Краулеры Telegram и WhatsApp не выполняют JavaScript, а Hosting отдаёт
статику — поэтому в превью показываются общие OG-теги, одинаковые для всех
товаров. Чтобы в превью появились название, цена и картинка конкретного товара,
нужен rewrite на Cloud Function, которая сходит в `api.iris-cosmetics.kz` и
отрисует `og:*` на сервере. Это требует тарифа Blaze.

## Смена домена на брендовый

Если понадобится `link.iris-cosmetics.kz` вместо `hibai-8a160.web.app`:

1. Firebase Console → Hosting → Add custom domain, выполнить указанные там
   DNS-записи и дождаться выпуска сертификата.
2. Заменить домен в пяти файлах из таблицы выше.
3. Передеплоить сайт и выпустить новую сборку приложения.

Домен в `AndroidManifest.xml` не добавлять «про запас»: на Android 12+ провал
верификации по одному host обнуляет её для всего intent-filter, включая рабочие
домены.
