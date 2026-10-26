import 'package:bai_market/core/app_pallete.dart';
import 'package:bai_market/core/widgets/main_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/user_address_model.dart';
import 'package:bai_market/features/create_order/presentation/widgets/region_choose.dart';
import 'package:bai_market/features/create_order/presentation/widgets/city_choose.dart';
import 'package:bai_market/features/my_address/presentation/cubit/my_address_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/app_localizations.dart';

class AddAddressPage extends StatefulWidget {
  /// Адрес, который правим. null — заводим новый.
  final UserAddressModel? address;

  const AddAddressPage({super.key, this.address});

  @override
  State<AddAddressPage> createState() => _AddAddressPageState();
}

class _AddAddressPageState extends State<AddAddressPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController labelController = TextEditingController();
  final TextEditingController regionController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController houseController = TextEditingController();
  final TextEditingController postalCodeController = TextEditingController();
  int? selectedRegionId;
  bool _submitting = false;

  bool get _isEditing => (widget.address?.id ?? 0) > 0;

  @override
  void initState() {
    super.initState();
    final address = widget.address;
    if (address == null) return;
    labelController.text = address.label;
    addressController.text = address.addressLine;
    postalCodeController.text = address.postalCode;
    // Регион и город хранятся в контроллерах как id. Пикеры название по id не
    // подтягивают и покажут подсказку, но пустыми поля уже не считаются.
    if (address.regionId > 0) {
      regionController.text = '${address.regionId}';
      selectedRegionId = address.regionId;
    }
    if (address.cityId > 0) cityController.text = '${address.cityId}';
    // У старых адресов дома нет — он внутри addressLine. Разбирать не беремся:
    // поле остаётся пустым и обязательным, покупатель дозаполнит сам.
    houseController.text = address.houseNumber ?? '';
  }

  @override
  void dispose() {
    labelController.dispose();
    regionController.dispose();
    cityController.dispose();
    addressController.dispose();
    houseController.dispose();
    postalCodeController.dispose();
    super.dispose();
  }

  void _handleRegionSelected(int regionId) {
    setState(() {
      selectedRegionId = regionId;
      cityController.clear();
    });
  }

  /// Индекс в адресной книге необязателен, но обрезанный «123» бэк отвергнет:
  /// если введён — строго 6 цифр.
  String? _validatePostal(String? value, AppLocalizations l10n) {
    final postal = (value ?? '').trim();
    if (postal.isEmpty) return null;
    if (!RegExp(r'^\d{6}$').hasMatch(postal)) {
      return l10n.postalCodeInvalidLength;
    }
    return null;
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;
    if (regionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.selectRegion), backgroundColor: Colors.redAccent));
      return;
    }
    if (cityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.selectCityFirst), backgroundColor: Colors.redAccent));
      return;
    }

    setState(() => _submitting = true);
    final cubit = context.read<MyAddressCubit>();
    final address = UserAddressModel(
      id: widget.address?.id ?? 0,
      regionId: int.tryParse(regionController.text) ?? 0,
      cityId: int.tryParse(cityController.text) ?? 0,
      // Только улица: дом едет отдельным полем houseNumber.
      addressLine: addressController.text.trim(),
      postalCode: postalCodeController.text.trim(),
      label: labelController.text.trim(),
      houseNumber: houseController.text.trim(),
    );
    // Кубит не бросает: null — успех, иначе текст ошибки. Пустая строка
    // значит «сервер ничего не пояснил» — показываем свою общую фразу.
    final error = _isEditing ? await cubit.updateAddress(widget.address!.id, address) : await cubit.addAddress(address);
    if (!mounted) return;
    if (error != null) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.isEmpty ? l10n.addressSaveError : error), backgroundColor: Colors.red));
      return;
    }
    if (!_isEditing) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.addressAdded), backgroundColor: Colors.green));
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.deliveryAddressTitle,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black),
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Поля собраны на TextFormField: на голом TextField
                        // валидаторы не работали и форма сохраняла что угодно.
                        _LabeledTextField(
                          label: l10n.addressNameLabel,
                          hint: l10n.addressNameHint,
                          controller: labelController,
                          validator: (v) => (v == null || v.trim().isEmpty) ? l10n.enterAddressName : null,
                        ),

                        RegionChoose(controller: regionController, onRegionSelected: _handleRegionSelected),

                        CityChoose(controller: cityController, selectedRegionId: selectedRegionId),

                        // Подсказка про «улица и номер дома» тут больше не
                        // годится: дом теперь отдельным полем, иначе он уедет
                        // в оба сразу.
                        _LabeledTextField(
                          label: l10n.deliveryAddressTitle,
                          hint: l10n.specifyDeliveryAddress,
                          controller: addressController,
                          keyboardType: TextInputType.streetAddress,
                          validator: (v) => (v == null || v.trim().isEmpty) ? l10n.enterAddressLine : null,
                        ),

                        // Буквы и дроби нужны: «12А», «15/2». Бэк принимает
                        // любую строку до 100 символов.
                        _LabeledTextField(
                          label: l10n.houseNumberLabel,
                          hint: l10n.houseNumberHint,
                          controller: houseController,
                          inputFormatters: [LengthLimitingTextInputFormatter(100)],
                          validator: (v) => (v == null || v.trim().isEmpty) ? l10n.enterHouseNumber : null,
                        ),

                        _LabeledTextField(
                          label: l10n.postalCode,
                          hint: l10n.postalIndexHint,
                          controller: postalCodeController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                          validator: (v) => _validatePostal(v, l10n),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                MainButton(
                  onPressed: _submitting ? null : _submit,
                  text: _submitting ? l10n.savingInProgress : l10n.saveAddress,
                  color: mainColorLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Поле формы в стиле экрана: подпись сверху, серая заливка, скругление 12.
class _LabeledTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _LabeledTextField({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          style: const TextStyle(fontSize: 15, color: Colors.black, fontWeight: FontWeight.w400),
          decoration: InputDecoration(
            filled: true,
            fillColor: lightGray,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 15, color: Colors.black38, fontWeight: FontWeight.w400),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
