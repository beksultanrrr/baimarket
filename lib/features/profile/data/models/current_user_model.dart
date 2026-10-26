import 'package:json_annotation/json_annotation.dart';

part 'current_user_model.g.dart';

/// Роли, которые отдаёт бэк в `GET /users/me/profile`.
///
/// Строковые константы, а не Dart-enum: незнакомая роль с сервера не должна
/// ронять разбор ответа, и по умолчанию она трактуется как обычный покупатель.
abstract final class UserRoles {
  static const String user = 'USER';
  static const String seller = 'SELLER';
  static const String admin = 'ADMIN';
}

/// Вложенный профиль из `GET /users/me/profile`.
///
/// Не путать с [ProfileModel] (`GET /profile/me/summary`) — та плоская и
/// нужна экрану профиля со счётчиками избранного, призов и билетов. Здесь
/// только личность и роль.
@JsonSerializable()
class UserProfileModel {
  final int? userId;
  final String? firstName;
  final String? lastName;

  /// Имя файла в MinIO. Полный путь — `$imgUrl$avatarUrl`.
  final String? avatarUrl;

  const UserProfileModel({
    this.userId,
    this.firstName,
    this.lastName,
    this.avatarUrl,
  });

  String get displayName => [firstName, lastName]
      .whereType<String>()
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .join(' ');

  factory UserProfileModel.fromJson(Map<String, dynamic> json) =>
      _$UserProfileModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserProfileModelToJson(this);
}

/// Текущий пользователь — `GET /users/me/profile`.
///
/// Единственный источник роли на клиенте. До появления этой ручки приложение
/// вообще не знало, кто перед ним, и кнопку «Начать эфир» приходилось
/// показывать всем, разбирая 403 постфактум.
@JsonSerializable(explicitToJson: true)
class CurrentUserModel {
  final int id;
  final String? phoneNumber;

  /// `USER` | `SELLER` | `ADMIN`.
  final String? role;

  @JsonKey(defaultValue: true)
  final bool isActive;

  final String? createdAt;
  final String? updatedAt;
  final UserProfileModel? profile;

  const CurrentUserModel({
    required this.id,
    this.phoneNumber,
    this.role,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.profile,
  });

  String get _role => (role ?? '').toUpperCase();

  bool get isSeller => _role == UserRoles.seller;
  bool get isAdmin => _role == UserRoles.admin;

  /// Кому показываем вход в эфир.
  ///
  /// Только продавцу. Админ эфиры не ведёт — он выдаёт продавцам доступ к ним
  /// в админке, и по контракту `POST /live/start` требует роль `SELLER`.
  /// Отключённый аккаунт (`isActive: false`) исключаем: сервер всё равно
  /// ответит ему 403.
  ///
  /// Это только видимость кнопки. Право вещать по-прежнему решает сервер
  /// ответом на `POST /live/start` — у продавца может не быть выданного
  /// админом доступа к эфирам, и такого поля в этой ручке нет.
  bool get canOpenStreaming => isActive && isSeller;

  factory CurrentUserModel.fromJson(Map<String, dynamic> json) =>
      _$CurrentUserModelFromJson(json);
  Map<String, dynamic> toJson() => _$CurrentUserModelToJson(this);
}
