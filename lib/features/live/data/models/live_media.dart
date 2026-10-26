import '../../../../core/urls.dart';
import 'live_stream_model.dart';

/// Правила сборки URL картинок эфира. Единственное место, где они живут —
/// иначе фоллбэк обложки пришлось бы повторять и в ленте, и в карточке.
///
/// Бэк везде отдаёт **имена файлов** MinIO, а не ссылки. Значение, уже
/// начинающееся с `http` или `/`, берём как есть — так контракт разрешает.
String liveFileUrl(String? fileName) {
  final name = fileName?.trim() ?? '';
  if (name.isEmpty) return '';
  if (name.startsWith('http') || name.startsWith('/')) return name;
  return '$imgUrl$name';
}

/// Обложка карточки эфира: `coverUrl` → фото закреплённого товара → пусто.
///
/// Пустая строка — штатный исход, а не ошибка: у только что стартовавшего
/// эфира ещё нет ни обложки, ни закреплённого товара. Вызывающий рисует
/// брендовую заглушку и заголовок поверх неё.
String liveCoverImageUrl(LiveStreamModel stream) {
  final cover = liveFileUrl(stream.coverUrl);
  if (cover.isNotEmpty) return cover;
  return liveFileUrl(stream.pinnedModel?.firstPhoto);
}

/// Аватар продавца или автора сообщения в чате.
String liveAvatarUrl(String? fileName) => liveFileUrl(fileName);
