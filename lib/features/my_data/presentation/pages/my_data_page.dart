import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/app_dio.dart';
import '../../../../core/urls.dart';
import '../../../../core/widgets/main_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../profile/data/models/profile_model.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../widgets/avatar_uploader.dart';
import '../widgets/birth_date_field.dart';
import '../widgets/delete_account_text_button.dart';
import '../widgets/my_data_header.dart';
import '../widgets/name_field.dart';
import '../widgets/profile_phone_field.dart';
import '../widgets/surname_field.dart';

class MyDataPage extends StatefulWidget {
  const MyDataPage({super.key, required this.profileModel});

  final ProfileModel profileModel;

  @override
  State<MyDataPage> createState() => _MyDataPageState();
}

class _MyDataPageState extends State<MyDataPage> {
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _birthDate;
  late final TextEditingController _phone;
  final Dio _dio = appDio;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _firstName = TextEditingController(text: widget.profileModel.firstName);
    _lastName = TextEditingController(text: widget.profileModel.lastName);
    _birthDate = TextEditingController();
    _phone = TextEditingController(text: _stripLeadingCountry(widget.profileModel.phoneNumber));
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _birthDate.dispose();
    _phone.dispose();
    super.dispose();
  }

  String _stripLeadingCountry(String? raw) {
    if (raw == null) return '';
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10 && digits.startsWith('7')) {
      return digits.substring(1);
    }
    return digits;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (_firstName.text.trim().isEmpty || _lastName.text.trim().isEmpty) {
      _showError(l10n.fillAllFields);
      return;
    }
    setState(() => _saving = true);
    try {
      final response = await _dio.patch(
        '${mainUrl}profile',
        data: {'firstName': _firstName.text.trim(), 'lastName': _lastName.text.trim()},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        context.read<ProfileCubit>().getProfileData();
        Navigator.pop(context);
        return;
      }
      final msg = response.data is Map && response.data['message'] != null ? response.data['message'].toString() : 'Unknown error';
      _showError(l10n.profileUpdateError(msg));
    } catch (e) {
      if (!mounted) return;
      _showError(l10n.error(e.toString()));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16), duration: const Duration(seconds: 3)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final initial = (widget.profileModel.firstName?.trim().isNotEmpty ?? false) ? widget.profileModel.firstName!.trim() : (widget.profileModel.lastName?.trim() ?? '');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyDataHeader(title: l10n.myData),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AvatarUploader(initial: initial, imageUrl: widget.profileModel.avatarUrl ?? '', baseLabel: l10n.baseAvatar, selectLabel: l10n.selectAvatar),
                        const SizedBox(height: 24),
                        SurnameField(controller: _lastName),
                        const SizedBox(height: 16),
                        NameField(controller: _firstName),
                        const SizedBox(height: 16),
                        BirthDateField(controller: _birthDate),
                        const SizedBox(height: 16),
                        ProfilePhoneField(controller: _phone),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                MainButton(onPressed: _saving ? null : _save, text: l10n.save),
                const SizedBox(height: 10),
                Center(
                  child: DeleteAccountTextButton(text: l10n.deleteAccount, onPressed: () {}),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
