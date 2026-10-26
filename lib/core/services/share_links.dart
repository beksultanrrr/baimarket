import '../urls.dart';

/// Публичные ссылки, которыми пользователь делится наружу.
///
/// Одна точка сборки: домен нельзя склеивать по месту, иначе рано или поздно
/// уедет от того, что прописан в assetlinks.json и entitlements, — и ссылка
/// молча начнёт открываться в браузере вместо приложения.
class ShareLinks {
  const ShareLinks._();

  static String product(int id) => '$shareBaseUrl/product/$id';

  static String seller(int id) => '$shareBaseUrl/seller/$id';

  static String collection(String slug) => '$shareBaseUrl/collection/$slug';

  static String raffle(int id) => '$shareBaseUrl/raffle/$id';

  static String live(int id) => '$shareBaseUrl/live/$id';
}
