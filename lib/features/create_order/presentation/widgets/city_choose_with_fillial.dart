import 'package:bai_market/features/create_order/data/models/city_model.dart';
import 'package:bai_market/features/create_order/presentation/widgets/filial_choose.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../core/app_pallete.dart';
import '../../../../core/urls.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../live/presentation/widgets/live_shopping_scope.dart';

class CityChooseWithFillial extends StatefulWidget {
  const CityChooseWithFillial({
    super.key,
    required this.controller,
    required this.filialController,
  });

  final TextEditingController controller;
  final TextEditingController filialController;

  @override
  State<CityChooseWithFillial> createState() => _CityChooseWithFillialState();
}

class _CityChooseWithFillialState extends State<CityChooseWithFillial> {
  String? selectedCity;
  List<CityModel> cities = [];
  bool isLoading = false;
  String? errorMessage;
  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    fetchCities();
  }

  @override
  void dispose() {
    _dio.close();
    super.dispose();
  }

  // Функция для загрузки списка городов с API используя Dio
  Future<void> fetchCities() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Замените URL на ваш актуальный хост
      final response = await _dio.get('${mainUrl}city?onlyPickup=true');

      if (response.statusCode == 200) {
        final List<dynamic> citiesJson = response.data;
        setState(() {
          cities = citiesJson.map((city) => CityModel.fromJson(city)).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Ошибка загрузки городов: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Не удалось загрузить города';
        isLoading = false;
      });
      if (kDebugMode) {
        print('Ошибка при загрузке городов: $e');
      }
    }
  }

  void _showCitySelectionModal() {
    showModalBottomSheet(
      context: context,
      routeSettings: const RouteSettings(name: kLiveSheetRouteName),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),

      isScrollControlled: false,
      builder: (context) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Column(
              children: [
                Container(
                  height: 4,
                  width: 40,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Выберите город',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: mainColorLight,
                        ),
                      ),
                      CupertinoButton(
                        padding: const EdgeInsets.all(0),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            color: Color(0xFFF2F2F2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/icons/cancel.svg',
                              height: 24,
                              width: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  )
                else if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                        ElevatedButton(
                          onPressed: fetchCities,
                          child: const Text('Попробовать снова'),
                        ),
                      ],
                    ),
                  )
                else if (cities.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Список городов пуст'),
                  )
                else
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(30),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const ClampingScrollPhysics(),
                        itemCount: cities.length,
                        itemBuilder: (context, index) {
                          final city = cities[index];
                          final l10n = AppLocalizations.of(context)!;
                          final cityName = city.nameRu ?? city.nameKz ?? city.nameEn ?? l10n.noData;
                          return ListTile(
                            title: Text(
                              cityName,
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                selectedCity = cityName;
                              });
                              widget.controller.text = city.id.toString();
                              if (kDebugMode) {
                                print('Выбран город с ID: ${city.id}');
                              }
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      backgroundColor: Color(0xFFF7F7F7),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text(
            'Выберите город',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showCitySelectionModal,
          child: Container(
            height: 56,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: lightGray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedCity ?? 'Например: Алматы',
                  style: TextStyle(
                    fontSize: 15,
                    color: selectedCity != null ? Colors.black : Colors.black38,
                    fontWeight:
                        selectedCity != null
                            ? FontWeight.w500
                            : FontWeight.w400,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.black38),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        selectedCity != null
            ? FilialChoose(
              controller: widget.filialController,
              pickupUrls:
                  cities[int.parse(widget.controller.text) - 1].pickupUrls ??
                  [],
              city: selectedCity ?? 'Алматы',
            )
            : SizedBox(),
        selectedCity != null ? const SizedBox(height: 16) : SizedBox(),
      ],
    );
  }
}
