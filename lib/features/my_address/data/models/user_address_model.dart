class UserAddressModel {
  final int id;
  final int regionId;
  final int cityId;
  final String addressLine;
  final String postalCode;
  final String label;

  /// Дом и квартира одной строкой ("150, кв. 25, подъезд 2").
  /// У старых адресов бэк отдаёт null — там весь адрес целиком лежит в [addressLine].
  final String? houseNumber;

  UserAddressModel({
    required this.id,
    required this.regionId,
    required this.cityId,
    required this.addressLine,
    required this.postalCode,
    required this.label,
    this.houseNumber,
  });

  factory UserAddressModel.fromJson(Map<String, dynamic> json) {
    return UserAddressModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      regionId: (json['regionId'] as num?)?.toInt() ?? 0,
      cityId: (json['cityId'] as num?)?.toInt() ?? 0,
      addressLine: json['addressLine'] as String? ?? '',
      // индекс на всякий случай приводим к строке — ведущий ноль в числе бы потерялся
      postalCode: json['postalCode']?.toString() ?? '',
      label: json['label'] as String? ?? '',
      houseNumber: json['houseNumber'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'regionId': regionId,
    'cityId': cityId,
    'addressLine': addressLine,
    // Индекс необязателен, но если прислан — бэк требует ровно 6 цифр, пустую строку не шлём
    if (postalCode.isNotEmpty) 'postalCode': postalCode,
    'label': label,
    // Поле необязательное — пустое значение не отправляем вовсе
    if (houseNumber != null && houseNumber!.isNotEmpty) 'houseNumber': houseNumber,
  };
}
