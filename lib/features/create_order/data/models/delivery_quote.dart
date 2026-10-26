// Расчёт доставки Казпочтой — ответ `POST /delivery/quote`.
//
// Парсер написан руками, без `json_serializable`: ответ плоский, а лишний
// прогон build_runner ради двух классов не нужен.

/// Способ доставки. Значения на проводе — ровно те, что ждёт бэк.
enum DeliveryMethod {
  /// До отделения Казпочты. Заказ ждёт получателя в отделении.
  branch,

  /// До двери, курьером Казпочты по указанному адресу.
  door,
}

extension DeliveryMethodX on DeliveryMethod {
  /// Значение для тела запроса (`deliveryMethod`) и для сравнения с ответом.
  String get wire => switch (this) {
    DeliveryMethod.branch => 'BRANCH',
    DeliveryMethod.door => 'DOOR',
  };

  /// Обратный разбор. `null` — на всё незнакомое: новый способ доставки не
  /// должен ронять чекаут, вариант просто не покажем.
  static DeliveryMethod? fromWire(String? value) => switch (value) {
    'BRANCH' => DeliveryMethod.branch,
    'DOOR' => DeliveryMethod.door,
    _ => null,
  };
}

/// Один вариант доставки из `options`.
class DeliveryOption {
  const DeliveryOption({
    required this.method,
    required this.price,
    required this.source,
  });

  final DeliveryMethod method;

  /// Цена в тенге. Плюсуется к сумме товаров уже на бэке при создании заказа.
  final int price;

  /// `kazpost` — живой тариф, `fallback` — Казпочта не ответила и бэк подставил
  /// свой. **Пользователю не показываем**, поле нужно только логам.
  final String source;

  /// Возвращает `null`, если способ доставки незнаком либо элемент не объект.
  static DeliveryOption? fromJson(Object? json) {
    if (json is! Map) return null;
    final method = DeliveryMethodX.fromWire(json['method'] as String?);
    if (method == null) return null;
    return DeliveryOption(
      method: method,
      price: (json['price'] as num?)?.toInt() ?? 0,
      source: json['source']?.toString() ?? '',
    );
  }

  @override
  String toString() => 'DeliveryOption(${method.wire}, $price, $source)';
}

/// Ответ `POST /delivery/quote` целиком.
class DeliveryQuote {
  const DeliveryQuote({required this.weightGrams, required this.options});

  /// Вес корзины, посчитанный бэком. Клиент его никуда не отправляет.
  final int weightGrams;

  /// Бэк обещает ровно два варианта в порядке BRANCH, DOOR — ни пустого
  /// списка, ни одиночного варианта не бывает. Признака «по умолчанию» нет.
  final List<DeliveryOption> options;

  /// Вариант под конкретный способ доставки, `null` — если такого не пришло.
  DeliveryOption? optionFor(DeliveryMethod method) {
    for (final option in options) {
      if (option.method == method) return option;
    }
    return null;
  }

  factory DeliveryQuote.fromJson(Map<String, dynamic> json) {
    final raw = json['options'];
    final options = <DeliveryOption>[];
    if (raw is List) {
      for (final item in raw) {
        final option = DeliveryOption.fromJson(item);
        if (option != null) options.add(option);
      }
    }
    return DeliveryQuote(
      weightGrams: (json['weightGrams'] as num?)?.toInt() ?? 0,
      options: options,
    );
  }

  /// Защитный разбор для сырого `response.data` — тело может прийти строкой
  /// или вовсе не объектом, и это не повод ронять чекаут.
  static DeliveryQuote? tryParse(Object? json) => json is Map
      ? DeliveryQuote.fromJson(Map<String, dynamic>.from(json))
      : null;

  @override
  String toString() => 'DeliveryQuote($weightGrams g, $options)';
}
