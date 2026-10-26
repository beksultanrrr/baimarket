import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/app_pallete.dart';
import '../../../../core/urls.dart';
import '../../data/models/city_model.dart';
import '../../../live/presentation/widgets/live_shopping_scope.dart';

class FilialPickerResult {
  const FilialPickerResult({required this.city, required this.filialIndex});

  final CityModel city;
  final int filialIndex;
}

Future<FilialPickerResult?> showFilialPickerSheet({
  required BuildContext context,
  CityModel? initialCity,
  int? initialFilialIndex,
}) {
  return showModalBottomSheet<FilialPickerResult>(
    context: context,
    routeSettings: const RouteSettings(name: kLiveSheetRouteName),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FilialPickerSheet(
      initialCity: initialCity,
      initialFilialIndex: initialFilialIndex,
    ),
  );
}

class _FilialPickerSheet extends StatefulWidget {
  const _FilialPickerSheet({this.initialCity, this.initialFilialIndex});

  final CityModel? initialCity;
  final int? initialFilialIndex;

  @override
  State<_FilialPickerSheet> createState() => _FilialPickerSheetState();
}

class _FilialPickerSheetState extends State<_FilialPickerSheet> {
  final Dio _dio = Dio();
  List<CityModel> _cities = [];
  CityModel? _city;
  int? _selectedFilial;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _city = widget.initialCity;
    _selectedFilial = widget.initialFilialIndex;
    _loadCities();
  }

  @override
  void dispose() {
    _dio.close();
    super.dispose();
  }

  Future<void> _loadCities() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _dio.get('${mainUrl}city?onlyPickup=true');
      if (response.statusCode == 200) {
        final list = (response.data as List)
            .map((e) => CityModel.fromJson(e as Map<String, dynamic>))
            .toList();
        setState(() {
          _cities = list;
          _city ??= list.isNotEmpty ? list.first : null;
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Ошибка загрузки';
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _error = 'Не удалось загрузить города';
        _loading = false;
      });
    }
  }

  Future<void> _pickCity() async {
    if (_cities.isEmpty) return;
    final picked = await showModalBottomSheet<CityModel>(
      context: context,
      routeSettings: const RouteSettings(name: kLiveSheetRouteName),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: _cities.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, color: Color(0xFFEDEDED)),
          itemBuilder: (_, i) {
            final c = _cities[i];
            return ListTile(
              title: Text(
                _cityName(c),
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              onTap: () => Navigator.pop(context, c),
            );
          },
        ),
      ),
    );
    if (picked != null && picked.id != _city?.id) {
      setState(() {
        _city = picked;
        _selectedFilial = null;
      });
    }
  }

  String _cityName(CityModel c) =>
      c.nameRu ?? c.nameKz ?? c.nameEn ?? 'Город';

  @override
  Widget build(BuildContext context) {
    final filials = _city?.pickupUrls ?? const <String>[];
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF5F5F5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _pickCity,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: mainColorLight,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _city == null ? 'Город' : _cityName(_city!),
                              style: const TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.black,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 36,
                        width: 36,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE9E9E9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.black54,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _buildBody(filials, scrollController),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(List<String> filials, ScrollController controller) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (filials.isEmpty) {
      return _EmptyFilialsState(onChangeCity: _pickCity);
    }
    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: filials.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final isSelected = _selectedFilial == i;
        return _FilialTile(
          isSelected: isSelected,
          districtName: 'Бостандыкский район',
          addressLine: 'улица Абдуллы Розыбакиева, 112',
          hours: 'Работаем с 10:00 до 20:00',
          onTap: () {
            setState(() => _selectedFilial = i);
            Navigator.pop(
              context,
              FilialPickerResult(city: _city!, filialIndex: i),
            );
          },
        );
      },
    );
  }
}

class _FilialTile extends StatelessWidget {
  const _FilialTile({
    required this.isSelected,
    required this.districtName,
    required this.addressLine,
    required this.hours,
    required this.onTap,
  });

  final bool isSelected;
  final String districtName;
  final String addressLine;
  final String hours;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? mainColorLight : const Color(0xFFCFCFCF),
                    width: 2,
                  ),
                  color: isSelected ? mainColorLight : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    districtName,
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    addressLine,
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6E6E6E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hours,
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF9A9A9A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFilialsState extends StatelessWidget {
  const _EmptyFilialsState({required this.onChangeCity});
  final VoidCallback onChangeCity;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/icons/create_order/create_order_location.svg',
              height: 96,
              width: 96,
              colorFilter: const ColorFilter.mode(
                Color(0xFFBDBDBD),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Филиалы нет',
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Вашем городе нет\nфилиалы для самавывоз',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF9A9A9A),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onChangeCity,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8F1ED),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text(
                    'Изменить город',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: mainColorLight,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
