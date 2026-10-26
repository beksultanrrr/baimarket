import 'package:bai_market/core/urls.dart';
import 'package:bai_market/core/widgets/main_button.dart';
import 'package:bai_market/features/my_data/presentation/widgets/first_name_field.dart';
import 'package:bai_market/features/my_data/presentation/widgets/last_name_field.dart';
import 'package:bai_market/features/profile/data/models/profile_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';

import '../../../../l10n/app_localizations.dart';
import '../widgets/delete_account_button.dart';
import '../widgets/select_avatar.dart';
import '../../../profile/presentation/widgets/profile_list.dart';

class MyDataPage extends StatefulWidget {
  const MyDataPage({super.key, required this.profileModel});
  final ProfileModel profileModel;

  @override
  State<MyDataPage> createState() => _MyDataPageState();
}

class _MyDataPageState extends State<MyDataPage> {
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  final Dio dio = Dio(); // Инициализация Dio

  @override
  void initState() {
    firstNameController = TextEditingController(text: widget.profileModel.firstName);
    lastNameController = TextEditingController(text: widget.profileModel.lastName);
    super.initState();
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    dio.close(); // Закрытие Dio для освобождения ресурсов
    super.dispose();
  }

  final _storage = SharedPreferences.getInstance();
  Future<void> _updateProfile() async {
    final l10n = AppLocalizations.of(context)!;
    const String baseUrl = mainUrl; // Используем mainUrl из core/urls.dart
    final url = Uri.parse('${baseUrl}profile'); // Исправленный URL
    var storage = await _storage;
    String? token = storage.getString('auth_token');

    // Валидация полей
    if (firstNameController.text.isEmpty || lastNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fillAllFields), backgroundColor: Colors.red, duration: const Duration(seconds: 3), behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16)),
      );
      return;
    }

    try {
      dio.options.headers["authorization"] = "Bearer $token";
      final response = await dio.patch(
        url.toString(),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            // Если требуется токен авторизации, добавьте его здесь
            // 'Authorization': 'Bearer your_token_here',
          },
        ),
        data: {'firstName': firstNameController.text, 'lastName': lastNameController.text},
      );

      if (response.statusCode == 200) {
        profileCubitGlobal.getProfileData();
        // Успешно обновлено, выполняем pop
        Navigator.pop(context);
      } else {
        // Ошибка, показываем SnackBar с деталями
        final errorMessage = response.data['message'] ?? 'Unknown error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.profileUpdateError(errorMessage)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      // Обработка исключений (например, нет интернета)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.error(e.toString())), backgroundColor: Colors.red, duration: const Duration(seconds: 3), behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16)),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final l10n = AppLocalizations.of(context)!;
    final baseUrl = mainUrl;
    final url = Uri.parse('${baseUrl}users/me');
    var storage = await _storage;
    String? token = storage.getString('auth_token');

    // Подтверждение
    final confirmed = await showPlatformDeleteDialog(context, l10n);
    if (confirmed != true) return;

    try {
      dio.options.headers["authorization"] = "Bearer $token";
      final response = await dio.delete(url.toString(), options: Options(headers: {'Content-Type': 'application/json'}));
      if (response.statusCode == 200 || response.statusCode == 204 || response.statusCode == 201) {
        await storage.remove('auth_token');
        authCubit.logOut();
        if (mounted) {
          context.go('/auth');
          await Future.delayed(const Duration(milliseconds: 300));
          await showPlatformSuccessDialog(context, l10n.success, 'Аккаунт успешно удалён');
        }
      } else {
        final errorMessage = response.data['message'] ?? 'Unknown error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.profileUpdateError(errorMessage)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.error(e.toString())), backgroundColor: Colors.red, duration: const Duration(seconds: 3), behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.myData,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 32),
              SelectAvatar(imageUrl: widget.profileModel.avatarUrl ?? ''),
              const SizedBox(height: 32),
              FirstNameField(controller: firstNameController),
              LastNameField(controller: lastNameController),
              // PhoneNumberField(), // Раскомментируйте, если нужно
              const SizedBox(height: 4),
              MainButton(onPressed: _updateProfile, text: l10n.save),
              const Spacer(),
              DeleteAccountButton(text: l10n.deleteAccount, onPressed: _deleteAccount),
            ],
          ),
        ),
      ),
    );
  }
}

Future<bool?> showPlatformDeleteDialog(BuildContext context, AppLocalizations l10n) {
  if (Platform.isIOS) {
    return showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.deleteAccount),
        content: Text('Вы уверены, что хотите удалить аккаунт? Это действие необратимо.'),
        actions: [
          CupertinoDialogAction(child: Text('Отмена'), onPressed: () => Navigator.of(context).pop(false)),
          CupertinoDialogAction(isDestructiveAction: true, child: Text(l10n.deleteAccount), onPressed: () => Navigator.of(context).pop(true)),
        ],
      ),
    );
  } else {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteAccount),
        content: Text('Вы уверены, что хотите удалить аккаунт? Это действие необратимо.'),
        actions: [
          TextButton(child: Text('Отмена'), onPressed: () => Navigator.of(context).pop(false)),
          TextButton(
            child: Text(l10n.deleteAccount, style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
  }
}

Future<void> showPlatformSuccessDialog(BuildContext context, String title, String content) {
  if (Platform.isIOS) {
    return showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [CupertinoDialogAction(child: Text('OK'), onPressed: () => Navigator.of(context).pop())],
      ),
    );
  } else {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [TextButton(child: Text('OK'), onPressed: () => Navigator.of(context).pop())],
      ),
    );
  }
}
