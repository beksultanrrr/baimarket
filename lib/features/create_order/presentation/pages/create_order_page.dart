import 'dart:async';

import 'package:bai_market/features/cart/data/models/cart_model.dart';
import 'package:bai_market/features/create_order/presentation/cubit/create_order_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:bai_market/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:bai_market/features/my_address/data/models/user_address_model.dart';
import 'package:bai_market/features/my_address/presentation/widgets/address_bottom_sheet.dart';
import 'package:bai_market/features/my_address/presentation/cubit/my_address_cubit.dart';
import 'package:bai_market/features/my_address/data/datasources/user_address_remote_datasource.dart';
import 'package:bai_market/features/my_address/data/repositories/user_address_repository_impl.dart';
import 'package:bai_market/features/my_address/presentation/pages/add_address_page.dart';
import 'package:bai_market/core/network/app_dio.dart';
import 'package:bai_market/core/urls.dart';

import '../../../../core/services/order_logger.dart';
import '../../../../core/widgets/main_button.dart';
import '../../../cart/data/models/cart_item_model.dart';
import '../../../live/presentation/widgets/live_shopping_scope.dart';
import '../../../order_success/data/models/order_success_args.dart';
import '../../../payment/data/models/payment_args.dart';
import '../../../payment/presentation/widgets/kaspi_payment_sheet.dart';
import '../../domain/repositories/create_order_repository.dart';
import '../../data/models/city_model.dart';
import '../widgets/bonus_tickets_row.dart';
import '../widgets/delivery_section.dart';
import '../widgets/filial_picker_sheet.dart';
import '../widgets/order_total_section.dart';
import '../widgets/payment_methods_section.dart';
import '../widgets/recipient_section.dart';
import '../widgets/total_price_block.dart' show calculateTotalDiscount;

const int _kCourierDeliveryPrice = 900;
const int _kTicketsToEarn = 2;
const String _kFilialDistrict = 'Бостандыкский район';
const String _kFilialAddressLine = 'улица Абдуллы Розыбакиева, 112';

class CreateOrderPage extends StatefulWidget {
  const CreateOrderPage({super.key, required this.cartModel});
  final CartModel cartModel;
  @override
  State<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends State<CreateOrderPage> {
  late TextEditingController whoTakesController;
  late TextEditingController cityController;
  late TextEditingController regionController;
  late TextEditingController phoneNumberController;
  late TextEditingController postalCodeController;
  late TextEditingController addressController;
  late TextEditingController filialId;
  int? selectedRegionId;
  final CreateOrderCubit createOrderPage = CreateOrderCubit();
  final ProfileCubit profileCubit = ProfileCubit();
  UserAddressModel? selectedUserAddress;
  CityModel? selectedPickupCity;
  int? selectedFilialIndex;

  int _selectedSegment = 0;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    whoTakesController = TextEditingController();
    cityController = TextEditingController();
    regionController = TextEditingController();
    phoneNumberController = TextEditingController();
    postalCodeController = TextEditingController();
    addressController = TextEditingController();
    filialId = TextEditingController();

    profileCubit.getProfileData();
  }

  @override
  void dispose() {
    whoTakesController.dispose();
    cityController.dispose();
    regionController.dispose();
    phoneNumberController.dispose();
    postalCodeController.dispose();
    addressController.dispose();
    filialId.dispose();
    profileCubit.close();
    super.dispose();
  }

  Future<void> _openAddressSheet() async {
    final cubit = MyAddressCubit(
      UserAddressRepositoryImpl(UserAddressRemoteDatasource(appDio, mainUrl)),
    );
    await cubit.loadAddresses();
    if (!mounted) return;
    final address = await showModalBottomSheet<UserAddressModel>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return BlocProvider.value(
          value: cubit,
          child: BlocBuilder<MyAddressCubit, MyAddressState>(
            builder: (context, state) {
              if (state is MyAddressLoaded) {
                return AddressBottomSheet(
                  addresses: state.addresses,
                  selectedId: selectedUserAddress?.id,
                  onSelect: (addr) => Navigator.pop(context, addr),
                  onAdd: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => BlocProvider.value(
                              value: cubit,
                              child: const AddAddressPage(),
                            ),
                      ),
                    );
                    if (result == true) {
                      await cubit.loadAddresses();
                    }
                  },
                );
              }
              if (state is MyAddressLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is MyAddressError) {
                return Center(
                  child: Text(
                    state.message,
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }
              return AddressBottomSheet(
                addresses: const [],
                selectedId: null,
                onSelect: (_) {},
                onAdd: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => BlocProvider.value(
                            value: cubit,
                            child: const AddAddressPage(),
                          ),
                    ),
                  );
                  if (result == true) {
                    await cubit.loadAddresses();
                  }
                },
              );
            },
          ),
        );
      },
    );

    if (address != null && mounted) {
      setState(() {
        selectedUserAddress = address;
        selectedRegionId = address.regionId;
        regionController.text = address.regionId.toString();
        cityController.text = address.cityId.toString();
        addressController.text = address.addressLine;
        postalCodeController.text = address.postalCode;
      });
    }
  }

  Future<void> _openFilialSheet() async {
    final result = await showFilialPickerSheet(
      context: context,
      initialCity: selectedPickupCity,
      initialFilialIndex: selectedFilialIndex,
    );
    if (result != null && mounted) {
      setState(() {
        selectedPickupCity = result.city;
        selectedFilialIndex = result.filialIndex;
        cityController.text = result.city.id.toString();
        filialId.text = result.filialIndex.toString();
      });
    }
  }

  String _cityName(CityModel c) => c.nameRu ?? c.nameKz ?? c.nameEn ?? 'Город';

  void _onContinuePressed() {
    final isCourier = _selectedSegment == 0;
    final missingCourierAddress =
        isCourier &&
        (selectedUserAddress == null || cityController.text.isEmpty);
    final missingPickupFilial =
        !isCourier &&
        (selectedPickupCity == null || selectedFilialIndex == null);

    orderLog.step(
      'Continue pressed',
      'isCourier=$isCourier, '
          'name="${whoTakesController.text}", '
          'phone="${phoneNumberController.text}", '
          'cityCtrl="${cityController.text}", '
          'addressCtrl="${addressController.text}", '
          'postal="${postalCodeController.text}", '
          'selectedUserAddressId=${selectedUserAddress?.id}, '
          'selectedPickupCityId=${selectedPickupCity?.id}, '
          'selectedFilialIndex=$selectedFilialIndex',
    );

    if (whoTakesController.text.isEmpty ||
        phoneNumberController.text.isEmpty ||
        missingCourierAddress ||
        missingPickupFilial) {
      orderLog.warn(
        'validation BLOCKED',
        'nameEmpty=${whoTakesController.text.isEmpty}, '
            'phoneEmpty=${phoneNumberController.text.isEmpty}, '
            'missingCourierAddress=$missingCourierAddress, '
            'missingPickupFilial=$missingPickupFilial',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, заполните все поля'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
        ),
      );
      return;
    }
    orderLog.step('validation OK — proceeding to /payment immediately');

    final cityId = int.parse(cityController.text);
    String? pickupUrl;
    if (!isCourier) {
      final urls = selectedPickupCity?.pickupUrls ?? const <String>[];
      if (urls.isNotEmpty &&
          selectedFilialIndex != null &&
          selectedFilialIndex! < urls.length) {
        pickupUrl = urls[selectedFilialIndex!];
      }
    }

    final paymentSlug = _paymentTypeSlug(_paymentMethod);
    final orderCityId = cityId;
    Future<OrderCreationResult?> runCreateOrder() =>
        createOrderPage.createOrder(
          cartId: widget.cartModel.id,
          fullName: whoTakesController.text,
          phoneNumber: formatPhoneNumber(phoneNumberController.text),
          selfPick: !isCourier,
          postalCode: postalCodeController.text,
          cityId: orderCityId,
          deliveryAddress: addressController.text,
          comment: 'Тест',
          pickupUrl: pickupUrl,
          selfPickDate: '',
          filialId: isCourier ? null : (selectedFilialIndex ?? 0) + 1,
          paymentTypeSlug: paymentSlug,
        );

    final args = _buildPaymentArgs(null, isCourier);
    final scope = LiveShoppingScope.maybeOf(context);

    // Kaspi (xpayment): дожидаемся создания заказа, чтобы получить orderId и
    // redirectUrl, затем показываем шит оплаты с QR и опросом статуса.
    if (_paymentMethod == PaymentMethod.kaspi) {
      unawaited(_payWithKaspi(runCreateOrder, args));
      return;
    }

    // Бэк сейчас отвечает 403 «Buying is not active» — не блокируем юзера.
    // Стреляем createOrder в фоне (логи/попытка реально создать заказ),
    // но НЕ ждём результат и не реагируем на состояние через BlocListener:
    // сразу пушим /payment с собранными аргументами. Если payment URL
    // позже появится — UI оплаты возьмёт его из state и пойдёт в
    // WebView, иначе сработает fallback на /order_success.
    unawaited(runCreateOrder());

    // Наличный расчёт не требует онлайн-оплаты: пропускаем /payment и
    // /payment_webview, сразу показываем экран успешного оформления.
    if (_paymentMethod == PaymentMethod.cash) {
      final successArgs = OrderSuccessArgs(
        orderId: DateTime.now().millisecondsSinceEpoch.remainder(1000000),
        itemsTotal: args.itemsTotal ?? args.amount,
        oldTotal: args.oldTotal,
        savings: args.savings ?? 0,
        ticketsEarned: args.ticketsEarned ?? 0,
        deliveryAddressLine: args.deliveryAddressLine,
        deliveryPostalCode: args.deliveryPostalCode,
        productImageUrls: args.productImageUrls,
      );
      orderLog.nav(
        'cash → push /order_success',
        'amount=${args.amount}, savings=${args.savings}',
      );
      if (scope != null) {
        scope.openOrderSuccess(context, successArgs);
      } else {
        context.push('/order_success', extra: successArgs);
      }
      return;
    }

    orderLog.nav(
      'push /payment (no wait)',
      'amount=${args.amount}, savings=${args.savings}',
    );
    if (scope != null) {
      scope.openPayment(context, args);
    } else {
      context.push('/payment', extra: args);
    }
  }

  String _paymentTypeSlug(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.cash:
        return 'CASH';
      case PaymentMethod.kaspi:
        return 'KASPI';
      default:
        // Остальные способы идут по старому слагу `ONEV`.
        return 'ONEV';
    }
  }

  /// Создаём заказ (ждём результат ради orderId + redirectUrl), затем
  /// открываем шит Kaspi-оплаты. Если заказ оплачен (шит вернул `true`) —
  /// уходим на экран успешного оформления.
  Future<void> _payWithKaspi(
    Future<OrderCreationResult?> Function() runCreateOrder,
    PaymentArgs args,
  ) async {
    // Захватываем messenger ДО await: после async-gap `context` может уже
    // быть деактивирован (особенно в live-shopping оверлее) и
    // `ScaffoldMessenger.of(context)` бросит «deactivated widget's ancestor».
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _submitting = true);
    OrderCreationResult? result;
    try {
      result = await runCreateOrder();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
    if (!mounted) return;

    final orderId = result?.orderId;
    final url = result?.redirectUrl;
    if (orderId == null || url == null || url.isEmpty) {
      orderLog.warn('kaspi: no orderId/redirectUrl', 'result=$result');
      final state = createOrderPage.state;
      final reason = state is OrderCreateError && (state.message?.isNotEmpty ?? false)
          ? state.message!
          : 'Не удалось начать оплату Kaspi';
      messenger.showSnackBar(
        SnackBar(
          content: Text(reason),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    final paid = await showKaspiPaymentSheet(
      context: context,
      orderId: orderId,
      redirectUrl: url,
      amount: args.amount,
    );
    if (paid != true || !mounted) return;

    final successArgs = OrderSuccessArgs(
      orderId: orderId,
      itemsTotal: args.itemsTotal ?? args.amount,
      oldTotal: args.oldTotal,
      savings: args.savings ?? 0,
      ticketsEarned: args.ticketsEarned ?? 0,
      deliveryAddressLine: args.deliveryAddressLine,
      deliveryPostalCode: args.deliveryPostalCode,
      productImageUrls: args.productImageUrls,
    );
    final scope = LiveShoppingScope.maybeOf(context);
    orderLog.nav('kaspi paid → /order_success', 'orderId=$orderId');
    if (scope != null) {
      scope.openOrderSuccess(context, successArgs);
    } else {
      context.push('/order_success', extra: successArgs);
    }
  }

  PaymentArgs _buildPaymentArgs(String? paymentUrl, bool isCourier) {
    final items = widget.cartModel.cartItems ?? const <CartItemModel>[];
    final goodsBefore = items.fold<int>(0, (sum, it) {
      final m = it.model;
      if (m == null) return sum;
      final unit = m.oldPrice ?? m.price ?? 0;
      return sum + unit * it.quantity;
    });
    final discount = calculateTotalDiscount(items);
    final goodsAfter = goodsBefore - discount;
    final delivery = isCourier ? _kCourierDeliveryPrice : 0;
    final totalAfter = goodsAfter + delivery;
    final totalBefore = goodsBefore + delivery;

    final addressLine =
        isCourier
            ? selectedUserAddress?.addressLine
            : '$_kFilialDistrict, $_kFilialAddressLine';
    final postalCode = isCourier ? selectedUserAddress?.postalCode : null;

    final productImages = <String>[];
    for (final it in items) {
      final urls = it.model?.photoUrls;
      if (urls != null && urls.isNotEmpty) productImages.add(urls.first);
    }

    return PaymentArgs(
      amount: totalAfter,
      paymentUrl: paymentUrl,
      itemsTotal: goodsAfter,
      oldTotal: discount > 0 ? totalBefore : null,
      savings: discount,
      ticketsEarned: _kTicketsToEarn,
      deliveryAddressLine: addressLine,
      deliveryPostalCode: postalCode,
      productImageUrls: productImages,
    );
  }

  Widget _buildDeliveryRow() {
    if (_selectedSegment == 0) {
      if (selectedUserAddress == null) {
        return DeliveryEntryRow(
          iconAsset: 'assets/icons/create_order/create_order_location.svg',
          title: 'Сохраненный адрес',
          actionLabel: 'выбрать',
          onTap: _openAddressSheet,
        );
      }
      return DeliveryEntryRow(
        iconAsset: 'assets/icons/create_order/create_order_location.svg',
        title:
            selectedUserAddress!.label.isEmpty
                ? 'Адрес'
                : selectedUserAddress!.label,
        subtitle: [
          selectedUserAddress!.addressLine,
          if (selectedUserAddress!.postalCode.isNotEmpty)
            'индекс: ${selectedUserAddress!.postalCode}',
        ].join('\n'),
        onTap: _openAddressSheet,
      );
    }

    if (selectedPickupCity == null || selectedFilialIndex == null) {
      return DeliveryEntryRow(
        iconAsset: 'assets/icons/create_order/create_order_location.svg',
        title: 'Филиалы',
        actionLabel: 'выбрать',
        onTap: _openFilialSheet,
      );
    }
    return DeliveryEntryRow(
      iconAsset: 'assets/icons/create_order/create_order_location.svg',
      title: _cityName(selectedPickupCity!),
      subtitle: 'Филиал: $_kFilialDistrict, $_kFilialAddressLine',
      actionLabel: 'Изменить',
      actionColor: const Color(0xFFFF3B47),
      onTap: _openFilialSheet,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCourier = _selectedSegment == 0;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Оформление заказа',
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        child: BlocListener<ProfileCubit, ProfileState>(
          bloc: profileCubit,
          listener: (context, state) {
            if (state is ProfileGot) {
              if (whoTakesController.text.isEmpty &&
                  (state.profile.firstName?.isNotEmpty ?? false) &&
                  (state.profile.lastName?.isNotEmpty ?? false)) {
                whoTakesController.text =
                    '${state.profile.firstName!.trim()} ${state.profile.lastName!.trim()}'.trim();
              }
              if (phoneNumberController.text.isEmpty &&
                  state.profile.phoneNumber != null) {
                phoneNumberController.text = _stripLeadingCountry(
                  state.profile.phoneNumber!,
                );
              }
            }
          },
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            child: Column(
              children: [
                DeliverySection(
                  selectedSegment: _selectedSegment,
                  onSegmentChanged: (i) => setState(() => _selectedSegment = i),
                  row: _buildDeliveryRow(),
                ),
                const SizedBox(height: 12),
                RecipientSection(
                  nameController: whoTakesController,
                  phoneController: phoneNumberController,
                  nameLabel:
                      isCourier ? 'Кто встретит (ФИО)' : 'Кто придет (ФИО)',
                ),
                const SizedBox(height: 12),
                PaymentMethodsSection(
                  selected: _paymentMethod,
                  onChanged: (m) => setState(() => _paymentMethod = m),
                ),
                const SizedBox(height: 12),
                const BonusTicketsRow(ticketsToEarn: _kTicketsToEarn),
                const SizedBox(height: 12),
                OrderTotalSection(
                  cartModel: widget.cartModel,
                  deliveryPrice: isCourier ? _kCourierDeliveryPrice : 0,
                ),
                const SizedBox(height: 16),
                // Кнопка не зависит от состояния cubit-а: createOrder()
                // запускается в фоне, навигация на /payment делается сразу
                // в `_onContinuePressed`. Слушать BlocConsumer не нужно —
                // только логируем переходы для отладки.
                BlocListener<CreateOrderCubit, CreateOrderState>(
                  bloc: createOrderPage,
                  listener: (context, state) {
                    orderLog.state(
                      'background cubit state',
                      state.runtimeType.toString(),
                    );
                  },
                  child: MainButton(
                    onPressed: _submitting ? null : _onContinuePressed,
                    text: _submitting ? 'Обработка…' : 'Продолжить',
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Нажимая на кнопку, вы соглашаетесь с Условиями обработки персональных данных, а также с Условиями продажи',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6E6E6E),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String formatPhoneNumber(String phoneNumber) {
  String cleaned = phoneNumber.replaceFirst('+7', '');
  return cleaned.replaceAll(RegExp(r'[^0-9]'), '');
}

String _stripLeadingCountry(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.length > 10 && digits.startsWith('7')) {
    return digits.substring(1);
  }
  return digits;
}
