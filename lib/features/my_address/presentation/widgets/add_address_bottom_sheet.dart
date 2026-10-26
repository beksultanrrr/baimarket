import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/app_pallete.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/services/user_city_storage.dart';
import '../../../../core/widgets/main_button.dart';
import '../../../create_order/presentation/widgets/city_choose.dart';
import '../../../create_order/presentation/widgets/region_choose.dart';
import '../../data/models/user_address_model.dart';
import '../cubit/my_address_cubit.dart';
import '../../../live/presentation/widgets/live_shopping_scope.dart';

class AddAddressBottomSheet extends StatefulWidget {
  /// Адрес, который правим. null — заводим новый.
  final UserAddressModel? address;

  const AddAddressBottomSheet({super.key, this.address});

  static Future<bool?> show(BuildContext context, {UserAddressModel? address}) {
    final cubit = context.read<MyAddressCubit>();
    return showModalBottomSheet<bool>(
      context: context,
      routeSettings: const RouteSettings(name: kLiveSheetRouteName),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: BlocProvider.value(value: cubit, child: AddAddressBottomSheet(address: address)),
      ),
    );
  }

  @override
  State<AddAddressBottomSheet> createState() => _AddAddressBottomSheetState();
}

class _AddAddressBottomSheetState extends State<AddAddressBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _regionController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _houseController = TextEditingController();
  final _entranceController = TextEditingController();
  final _floorController = TextEditingController();
  final _postalController = TextEditingController();
  int? _selectedRegionId;
  String? _selectedCityName;
  bool _submitting = false;

  bool get _isEditing => (widget.address?.id ?? 0) > 0;

  @override
  void initState() {
    super.initState();
    final address = widget.address;
    if (address == null) return;
    _labelController.text = address.label;
    _addressController.text = address.addressLine;
    _postalController.text = address.postalCode;
    // Регион и город лежат в контроллерах как id — их читает форма при
    // сохранении. Пикеры своё название по id не подтягивают и покажут
    // подсказку, но невыбранными эти поля уже не считаются.
    if (address.regionId > 0) {
      _regionController.text = '${address.regionId}';
      _selectedRegionId = address.regionId;
    }
    if (address.cityId > 0) _cityController.text = '${address.cityId}';
    // У старых адресов дома нет вовсе — он внутри addressLine. Разбирать
    // его не беремся, поле остаётся пустым и обязательным: покупатель
    // дозаполнит сам, заводить адрес заново не придётся.
    _houseController.text = address.houseNumber ?? '';
  }

  @override
  void dispose() {
    _labelController.dispose();
    _regionController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _houseController.dispose();
    _entranceController.dispose();
    _floorController.dispose();
    _postalController.dispose();
    super.dispose();
  }

  /// Собирает строку дома для бэка: дом с квартирой так, как ввёл покупатель,
  /// плюс подъезд и этаж. Это единственное поле адреса помимо улицы и города,
  /// которое доезжает до Казпочты, поэтому всё складываем сюда.
  ///
  /// Части намеренно НЕ локализованы: строка уходит на сервер, попадает в
  /// заказ и читается курьером — формат должен быть один независимо от языка
  /// интерфейса покупателя.
  String _composeHouseNumber() {
    final parts = <String>[_houseController.text.trim()];
    if (_entranceController.text.trim().isNotEmpty) {
      parts.add('подъезд ${_entranceController.text.trim()}');
    }
    if (_floorController.text.trim().isNotEmpty) {
      parts.add('этаж ${_floorController.text.trim()}');
    }
    return parts.where((p) => p.isNotEmpty).join(', ');
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;
    if (_regionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.selectRegion), backgroundColor: Colors.redAccent));
      return;
    }
    if (_cityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.selectCityFirst), backgroundColor: Colors.redAccent));
      return;
    }

    setState(() => _submitting = true);
    try {
      final cubit = context.read<MyAddressCubit>();
      final address = UserAddressModel(
        id: widget.address?.id ?? 0,
        regionId: int.tryParse(_regionController.text) ?? 0,
        cityId: int.tryParse(_cityController.text) ?? 0,
        // Только улица: дом уехал в houseNumber, склеивать их обратно нельзя —
        // до Казпочты они едут разными полями.
        addressLine: _addressController.text.trim(),
        postalCode: _postalController.text.trim(),
        label: _labelController.text.trim(),
        houseNumber: _composeHouseNumber(),
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
      if (_selectedCityName != null && _selectedCityName!.isNotEmpty) {
        await setUserCity(_selectedCityName!);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.error(e.toString())), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final maxHeight = MediaQuery.of(context).size.height * 0.9;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderRow(title: _selectedCityName?.isNotEmpty == true ? _selectedCityName! : l10n.newAddress, onClose: () => Navigator.of(context).pop()),
                const SizedBox(height: 20),
                _FilledTextField(controller: _labelController, hint: l10n.addressNameHint, validator: (v) => (v == null || v.trim().isEmpty) ? l10n.enterAddressName : null),
                const SizedBox(height: 16),
                RegionChoose(
                  controller: _regionController,
                  onRegionSelected: (id) => setState(() {
                    _selectedRegionId = id;
                    _cityController.clear();
                    _selectedCityName = null;
                  }),
                ),
                CityChoose(controller: _cityController, selectedRegionId: _selectedRegionId, onCitySelected: (name) => setState(() => _selectedCityName = name)),
                _FieldLabel(l10n.deliveryAddressTitle),
                const SizedBox(height: 8),
                // Подсказка про «улица и номер дома» тут больше не годится:
                // дом теперь отдельным полем, иначе он уедет в оба сразу.
                _FilledTextField(controller: _addressController, hint: l10n.specifyDeliveryAddress, validator: (v) => (v == null || v.trim().isEmpty) ? l10n.enterAddressLine : null),
                const SizedBox(height: 16),
                _LabeledField(
                  label: l10n.houseNumberLabel,
                  child: _FilledTextField(
                    controller: _houseController,
                    hint: l10n.houseNumberHint,
                    // Буквы и дроби нужны: «12А», «15/2». Бэк принимает
                    // любую строку до 100 символов.
                    inputFormatters: [LengthLimitingTextInputFormatter(100)],
                    validator: (v) => (v == null || v.trim().isEmpty) ? l10n.enterHouseNumber : null,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _LabeledField(
                        label: l10n.entranceLabel,
                        child: _FilledTextField(
                          controller: _entranceController,
                          hint: l10n.entranceLabel,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _LabeledField(
                        label: l10n.floorLabel,
                        child: _FilledTextField(controller: _floorController, hint: l10n.floorLabel, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _FieldLabel(l10n.postalCode),
                    GestureDetector(
                      onTap: () {},
                      child: const Text(
                        'КазПочта',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF71CD32)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _FilledTextField(
                  controller: _postalController,
                  hint: l10n.postalIndexHint,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                  // В адресной книге индекс необязателен, но обрезанный «123»
                  // бэк отвергнет: если введён — строго 6 цифр.
                  validator: (v) => _validatePostal(v, l10n),
                ),
                const SizedBox(height: 24),
                MainButton(onPressed: _submitting ? null : _submit, text: _submitting ? l10n.savingInProgress : (_isEditing ? l10n.save : l10n.addAction), color: mainColorLight),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _validatePostal(String? value, AppLocalizations l10n) {
    final postal = (value ?? '').trim();
    if (postal.isEmpty) return null;
    if (!RegExp(r'^\d{6}$').hasMatch(postal)) return l10n.postalCodeInvalidLength;
    return null;
  }
}

class _HeaderRow extends StatelessWidget {
  final String title;
  final VoidCallback onClose;
  const _HeaderRow({required this.title, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.black),
        ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: const Size(32, 32),
          onPressed: onClose,
          child: Container(
            height: 32,
            width: 32,
            decoration: const BoxDecoration(color: lightGray, shape: BoxShape.circle),
            child: const Icon(Icons.close, size: 18, color: Colors.black54),
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_FieldLabel(label), const SizedBox(height: 8), child]);
  }
}

class _FilledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _FilledTextField({required this.controller, required this.hint, this.keyboardType, this.inputFormatters, this.validator});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
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
    );
  }
}
