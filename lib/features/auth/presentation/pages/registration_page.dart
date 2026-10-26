import 'package:bai_market/core/app_pallete.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';

/// Экран заполнения данных после входа: имя, фамилия, город → «Продолжить».
class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  String? _city;

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    super.dispose();
  }

  void _onSelectCity() {
    // TODO: подключить выбор города (API `city?regionId=...`).
  }

  void _onContinue() {
    // TODO: сохранить данные профиля и перейти к следующему шагу.
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      if (context.canPop()) context.pop();
                    },
                    icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
                  ),
                ),

                const SizedBox(height: 32),

                Text(
                  l10n.fillInData,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                    color: mainColorLight,
                    fontFamily: 'Gilroy',
                  ),
                ),

                const SizedBox(height: 28),

                _InputField(
                  controller: _nameController,
                  hint: l10n.name,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                _InputField(
                  controller: _surnameController,
                  hint: l10n.surname,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                _CityField(value: _city, hint: l10n.selectCity, onTap: _onSelectCity),

                const SizedBox(height: 28),

                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkButtonColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      l10n.continueAction,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: 'Gilroy',
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Серое скруглённое текстовое поле с плейсхолдером (как на макете).
class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hint,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String hint;
  final TextCapitalization textCapitalization;

  static final _border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide.none,
  );

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textCapitalization: textCapitalization,
      style: const TextStyle(
        fontSize: 16,
        color: Colors.black,
        fontWeight: FontWeight.w500,
        fontFamily: 'Gilroy',
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 16,
          color: Color(0xFFB0B0B0),
          fontWeight: FontWeight.w400,
          fontFamily: 'Gilroy',
        ),
        filled: true,
        fillColor: const Color(0xFFF2F2F2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: _border,
        enabledBorder: _border,
        focusedBorder: _border,
      ),
    );
  }
}

/// Поле-«дропдаун» выбора города: плейсхолдер + шеврон.
class _CityField extends StatelessWidget {
  const _CityField({required this.value, required this.hint, required this.onTap});

  final String? value;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                hasValue ? value! : hint,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: hasValue ? FontWeight.w500 : FontWeight.w400,
                  color: hasValue ? Colors.black : const Color(0xFFB0B0B0),
                  fontFamily: 'Gilroy',
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Color(0xFF8A8A8A)),
          ],
        ),
      ),
    );
  }
}
