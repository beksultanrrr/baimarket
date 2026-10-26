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
import 'package:bai_market/core/ui/root_messenger.dart';
import 'package:bai_market/core/urls.dart';

import '../../../../core/services/order_logger.dart';
import '../../../../core/widgets/consent_text.dart';
import '../../../../core/widgets/main_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../cart/data/models/cart_item_model.dart';
import '../../../live/presentation/widgets/live_shopping_scope.dart';
import '../../../order_success/data/models/order_success_args.dart';
import '../../../payment/data/models/payment_args.dart';
import '../../../payment/presentation/widgets/kaspi_payment_sheet.dart';
import '../../data/models/delivery_quote.dart';
import '../../domain/repositories/create_order_repository.dart';
import '../widgets/address_field.dart';
import '../widgets/bonus_tickets_row.dart';
import '../widgets/delivery_section.dart';
import '../widgets/order_total_section.dart';
import '../widgets/payment_methods_section.dart';
import '../widgets/postal_field.dart';
import '../widgets/recipient_section.dart';
import '../widgets/total_price_block.dart' show calculateTotalDiscount;

const int _kTicketsToEarn = 2;

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

  /// ТОЛЬКО улица: дом и квартира уходят отдельным полем.
  late TextEditingController addressController;

  /// Дом и квартира одной строкой — «150, кв. 25, подъезд 2». Единственное,
  /// что доезжает до Казпочты помимо улицы и города, поэтому обязательное.
  late TextEditingController houseNumberController;

  int? selectedRegionId;
  final CreateOrderCubit createOrderPage = CreateOrderCubit();
  final ProfileCubit profileCubit = ProfileCubit();
  UserAddressModel? selectedUserAddress;

  /// Способ доставки. Признака «по умолчанию» контракт не даёт, поэтому до
  /// выбора покупателя здесь `null` и «Продолжить» ругается.
  DeliveryMethod? _deliveryMethod;

  /// Единственный доступный способ оплаты — карточка «Наличными» убрана из
  /// `payment_methods_section.dart`, поэтому Kaspi выбран сразу.
  PaymentMethod _paymentMethod = PaymentMethod.kaspi;
  bool _submitting = false;

  /// Покупатель уже пытался оформить заказ без выбранного адреса — подсвечиваем
  /// строку адреса красным, чтобы причина отказа осталась на экране, а не
  /// уехала вместе со снекбаром.
  bool _addressMissing = false;

  /// Индекс дописан до шести цифр. Держим отдельным полем, потому что
  /// подсказка под способами доставки зависит от него, а состояние кубита
  /// при вводе индекса не меняется (остаётся `Idle`) и перестройки не даёт.
  bool _postalReady = false;

  /// Город берётся ИСКЛЮЧИТЕЛЬНО из адресной книги: отдельного селектора
  /// города на экране нет и быть не должно — два источника правды разъедутся.
  /// [cityController] — техническое хранилище подстановки из выбранного
  /// адреса, поэтому читаем сначала сам адрес, а его — как запасной вариант.
  int? get _cityId {
    final fromAddress = selectedUserAddress?.cityId;
    if (fromAddress != null && fromAddress > 0) return fromAddress;
    final parsed = int.tryParse(cityController.text.trim());
    return (parsed != null && parsed > 0) ? parsed : null;
  }

  /// Индекс — ровно шесть цифр, иначе бэк отдаст 400.
  static final RegExp _postalCodeRe = RegExp(r'^\d{6}$');

  @override
  void initState() {
    super.initState();
    whoTakesController = TextEditingController();
    cityController = TextEditingController();
    regionController = TextEditingController();
    phoneNumberController = TextEditingController();
    postalCodeController = TextEditingController();
    addressController = TextEditingController();
    houseNumberController = TextEditingController();

    // Индекс меняется и руками, и подстановкой из сохранённого адреса —
    // поэтому котировку дёргаем из слушателя контроллера, а не из onChanged
    // поля: иначе программная подстановка расчёт не запустит.
    postalCodeController.addListener(_onPostalCodeChanged);

    profileCubit.getProfileData();
  }

  @override
  void dispose() {
    postalCodeController.removeListener(_onPostalCodeChanged);
    whoTakesController.dispose();
    cityController.dispose();
    regionController.dispose();
    phoneNumberController.dispose();
    postalCodeController.dispose();
    addressController.dispose();
    houseNumberController.dispose();
    profileCubit.close();
    // Кубит страницы свой, не из main.dart: закрываем сами, иначе дебаунс
    // котировки переживёт экран.
    createOrderPage.close();
    super.dispose();
  }

  /// Отсев коротких значений и дебаунс — внутри `DeliveryQuoteCubit`,
  /// здесь фильтровать нечего.
  void _onPostalCodeChanged() {
    final ready = _postalCodeRe.hasMatch(postalCodeController.text.trim());
    if (ready != _postalReady && mounted) setState(() => _postalReady = ready);
    createOrderPage.loadQuote(postalCodeController.text, _cityId);
  }

  Future<void> _openAddressSheet() async {
    final cubit = MyAddressCubit(UserAddressRepositoryImpl(UserAddressRemoteDatasource(appDio, mainUrl)));
    await cubit.loadAddresses();
    if (!mounted) return;
    final address = await showModalBottomSheet<UserAddressModel>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                    final result = await liveAwarePushWidget<bool>(context, BlocProvider.value(value: cubit, child: const AddAddressPage()));
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
                  child: Text(AppLocalizations.of(context)!.addressesLoadError, style: const TextStyle(color: Colors.red)),
                );
              }
              return AddressBottomSheet(
                addresses: const [],
                selectedId: null,
                onSelect: (_) {},
                onAdd: () async {
                  final result = await liveAwarePushWidget<bool>(context, BlocProvider.value(value: cubit, child: const AddAddressPage()));
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
        _addressMissing = false;
        selectedRegionId = address.regionId;
        regionController.text = address.regionId.toString();
        cityController.text = address.cityId.toString();
        addressController.text = address.addressLine;
        postalCodeController.text = address.postalCode;
        // Старые адреса бэк не парсил: у них дома нет, а весь адрес лежит
        // в `addressLine`. Тогда улицу подставляем как есть, а поле дома
        // оставляем пустым — покупатель дозаполнит, заново вводить адрес
        // не просим.
        houseNumberController.text = address.houseNumber?.trim() ?? '';
      });
      // В расчёт уходит и город, а слушатель индекса молчит, если у нового
      // адреса индекс тот же — дёргаем расчёт руками.
      createOrderPage.loadQuote(postalCodeController.text, _cityId);
    }
  }

  /// Ошибки показываем ТОЛЬКО через корневой мессенджер
  /// (см. [showRootSnackBar]): в live-shopping оверлее ближайший к экрану
  /// мессенджер держит уже деактивированный Scaffold, и `showSnackBar` на нём
  /// падает даже без async-gap. Ближайший остаётся аварийным фолбэком, а сам
  /// показ никогда не бросает — сообщение об ошибке не должно ронять экран.
  void _showError(String message) {
    final shown = showRootSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16)),
      fallbackContext: mounted ? context : null,
    );
    if (!shown) orderLog.warn('snackbar not shown', message);
  }

  Future<void> _onContinuePressed() async {
    final l10n = AppLocalizations.of(context)!;
    final postalCode = postalCodeController.text.trim();
    final street = addressController.text.trim();
    final houseNumber = houseNumberController.text.trim();
    final method = _deliveryMethod;
    final cityId = _cityId;

    orderLog.step(
      'Continue pressed',
      'name="${whoTakesController.text}", '
          'phone="${phoneNumberController.text}", '
          'cityId=$cityId, '
          'street="$street", '
          'houseNumber="$houseNumber", '
          'postal="$postalCode", '
          'deliveryMethod=${method?.wire}, '
          'selectedUserAddressId=${selectedUserAddress?.id}',
    );

    // Город приходит только вместе с сохранённым адресом, поля города на
    // экране нет. Поэтому «адрес не выбран» — отдельная причина отказа, её
    // нельзя прятать за общим «заполните все поля»: иначе покупатель, вбивший
    // индекс и улицу руками, не понимает, чего от него хотят.
    if (cityId == null) {
      orderLog.warn('validation BLOCKED', 'cityId=null (сохранённый адрес не выбран)');
      setState(() => _addressMissing = true);
      _showError(l10n.selectSavedAddressFirst);
      return;
    }
    if (whoTakesController.text.isEmpty || phoneNumberController.text.isEmpty || street.isEmpty || method == null) {
      orderLog.warn(
        'validation BLOCKED',
        'nameEmpty=${whoTakesController.text.isEmpty}, '
            'phoneEmpty=${phoneNumberController.text.isEmpty}, '
            'cityId=$cityId, streetEmpty=${street.isEmpty}, '
            'methodEmpty=${method == null}',
      );
      _showError(l10n.fillAllFields);
      return;
    }
    if (!_postalCodeRe.hasMatch(postalCode)) {
      orderLog.warn('validation BLOCKED', 'postalCode="$postalCode"');
      _showError(l10n.postalCodeInvalidLength);
      return;
    }
    if (houseNumber.isEmpty) {
      orderLog.warn('validation BLOCKED', 'houseNumber empty');
      _showError(l10n.enterHouseNumber);
      return;
    }
    orderLog.step('validation OK — creating order');

    // Заказ создаём ДО навигации: 400 от бэка теперь штатный ответ (индекс,
    // дом, пустая корзина) и его надо показать, а сумма к оплате приходит
    // только в ответе — считать её на клиенте нельзя.
    setState(() => _submitting = true);
    OrderCreationResult? result;
    try {
      result = await createOrderPage.createOrder(
        cartId: widget.cartModel.id,
        fullName: whoTakesController.text,
        phoneNumber: formatPhoneNumber(phoneNumberController.text),
        postalCode: postalCode,
        cityId: cityId,
        deliveryMethod: method,
        deliveryAddress: street,
        houseNumber: houseNumber,
        comment: '',
        paymentTypeSlug: _paymentTypeSlug(_paymentMethod),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
    if (!mounted) return;

    final orderId = result?.orderId;
    if (result == null || orderId == null) {
      final state = createOrderPage.state;
      final reason = state is OrderCreateError && (state.message?.isNotEmpty ?? false) ? state.message! : l10n.streamErrorGeneric;
      orderLog.warn('order not created', 'result=$result');
      _showError(reason);
      return;
    }

    final args = _buildPaymentArgs(result);

    // Kaspi (xpayment): заказ уже создан, показываем шит оплаты с QR и
    // опросом статуса.
    if (_paymentMethod == PaymentMethod.kaspi) {
      await _payWithKaspi(result, args);
      return;
    }

    // Наличный расчёт не требует онлайн-оплаты: пропускаем /payment и
    // /payment_webview, сразу показываем экран успешного оформления.
    if (_paymentMethod == PaymentMethod.cash) {
      orderLog.nav('cash → push /order_success', 'orderId=$orderId, amount=${args.amount}');
      liveAwarePush(context, '/order_success', extra: _buildSuccessArgs(args, result));
      return;
    }

    orderLog.nav('push /payment', 'orderId=$orderId, amount=${args.amount}, delivery=${args.deliveryPrice}');
    liveAwarePush(context, '/payment', extra: args);
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

  /// Шит Kaspi-оплаты по уже созданному заказу. Если заказ оплачен (шит
  /// вернул `true`) — уходим на экран успешного оформления.
  Future<void> _payWithKaspi(OrderCreationResult result, PaymentArgs args) async {
    // l10n захватываем ДО await: после async-gap `context` может уже быть
    // деактивирован (особенно в live-shopping оверлее). Мессенджер захватывать
    // не нужно — снекбары идут через корневой ключ.
    final l10n = AppLocalizations.of(context)!;
    final orderId = result.orderId!;
    final url = result.redirectUrl;
    if (url == null || url.isEmpty) {
      orderLog.warn('kaspi: no redirectUrl', 'orderId=$orderId');
      _showError(l10n.kaspiPaymentStartFailed);
      return;
    }

    final paid = await showKaspiPaymentSheet(context: context, orderId: orderId, redirectUrl: url, amount: args.amount);
    if (paid != true || !mounted) return;

    orderLog.nav('kaspi paid → /order_success', 'orderId=$orderId');
    liveAwarePush(context, '/order_success', extra: _buildSuccessArgs(args, result));
  }

  /// Аргументы оплаты собираем ИЗ ОТВЕТА бэка: цена доставки фиксируется при
  /// создании заказа и уже зашита в платёжную ссылку, а `totalPrice` — это
  /// только товары. Локальный подсчёт остаётся лишь как страховка на случай,
  /// если полей в ответе не окажется.
  PaymentArgs _buildPaymentArgs(OrderCreationResult result) {
    final items = widget.cartModel.cartItems ?? const <CartItemModel>[];
    final goodsBefore = items.fold<int>(0, (sum, it) {
      final m = it.model;
      if (m == null) return sum;
      final unit = m.oldPrice ?? m.price ?? 0;
      return sum + unit * it.quantity;
    });
    final discount = calculateTotalDiscount(items);
    final goodsAfter = goodsBefore - discount;

    // Предварительная сумма товаров — серверная (`cartModel.totalPrice`):
    // локальный fold по `oldPrice` считает цены ДО скидки и с серверным итогом
    // не сходится. Он остаётся только как последний фолбэк.
    final itemsTotal = result.totalPrice ?? widget.cartModel.totalPrice ?? goodsAfter;
    final delivery = result.deliveryPrice ?? 0;

    final productImages = <String>[];
    for (final it in items) {
      final urls = it.model?.photoUrls;
      if (urls != null && urls.isNotEmpty) productImages.add(urls.first);
    }

    return PaymentArgs(
      amount: itemsTotal + delivery,
      paymentUrl: result.redirectUrl,
      itemsTotal: itemsTotal,
      oldTotal: discount > 0 ? goodsBefore + delivery : null,
      savings: discount,
      ticketsEarned: _kTicketsToEarn,
      deliveryAddressLine: _fullAddressLine(),
      deliveryPostalCode: postalCodeController.text.trim(),
      productImageUrls: productImages,
      deliveryPrice: delivery,
      deliveryMethod: _deliveryMethod?.wire,
      orderId: result.orderId,
    );
  }

  OrderSuccessArgs _buildSuccessArgs(PaymentArgs args, OrderCreationResult result) {
    return OrderSuccessArgs(
      orderId: result.orderId ?? 0,
      itemsTotal: args.itemsTotal ?? args.amount,
      oldTotal: args.oldTotal,
      savings: args.savings ?? 0,
      ticketsEarned: args.ticketsEarned ?? 0,
      deliveryAddressLine: args.deliveryAddressLine,
      deliveryPostalCode: args.deliveryPostalCode,
      productImageUrls: args.productImageUrls,
      deliveryPrice: args.deliveryPrice,
      trackingNumber: result.trackingNumber,
    );
  }

  /// Улица и дом одной строкой — только для показа в чеке и на success-экране.
  /// В API они уходят раздельно.
  String _fullAddressLine() {
    final parts = [addressController.text.trim(), houseNumberController.text.trim()].where((part) => part.isNotEmpty);
    return parts.join(', ');
  }

  Widget _buildDeliveryRow() {
    final l10n = AppLocalizations.of(context)!;
    if (selectedUserAddress == null) {
      // Город приходит только с сохранённым адресом, поэтому выбор адреса —
      // обязательный шаг, а не опция: пишем это прямо в строке-подсказке, а
      // после неудачной попытки оформить заказ красим её в красный.
      return DeliveryEntryRow(
        iconAsset: 'assets/icons/create_order/create_order_location_tick.svg',
        title: l10n.savedAddressTitle,
        actionLabel: l10n.selectSavedAddressFirst,
        actionColor: _addressMissing ? const Color(0xFFFF3B47) : const Color(0xFF39951F),
        onTap: _openAddressSheet,
      );
    }
    return DeliveryEntryRow(
      iconAsset: 'assets/icons/create_order/create_order_location_tick.svg',
      title: selectedUserAddress!.label.isEmpty ? l10n.addressFallbackTitle : selectedUserAddress!.label,
      subtitle: [selectedUserAddress!.addressLine, if (selectedUserAddress!.postalCode.isNotEmpty) l10n.postalIndex(selectedUserAddress!.postalCode)].join('\n'),
      onTap: _openAddressSheet,
    );
  }

  /// Что показать вместо цены доставки. `null` — расчёт пришёл, цены есть.
  String? _quoteStatusText(DeliveryQuoteState state, AppLocalizations l10n) {
    if (state is DeliveryQuoteLoading) return l10n.deliveryPriceCalculating;
    if (state is DeliveryQuoteError) return l10n.deliveryQuoteFailed;
    if (state is DeliveryQuoteLoaded) return null;
    // Расчёт идёт по паре «индекс + город». Пока индекс не дописан — просим
    // индекс; когда он готов, а адрес не выбран — просим адрес, иначе
    // подсказка советовала бы ввести уже введённое.
    if (_postalReady && _cityId == null) return l10n.selectAddressForDelivery;
    return l10n.enterPostalForDelivery;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
        title: Text(
          l10n.checkoutTitle,
          style: const TextStyle(fontFamily: 'Gilroy', fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black),
        ),
      ),
      body: SafeArea(
        child: BlocListener<ProfileCubit, ProfileState>(
          bloc: profileCubit,
          listener: (context, state) {
            if (state is ProfileGot) {
              if (whoTakesController.text.isEmpty && (state.profile.firstName?.isNotEmpty ?? false) && (state.profile.lastName?.isNotEmpty ?? false)) {
                whoTakesController.text = '${state.profile.firstName!.trim()} ${state.profile.lastName!.trim()}'.trim();
              }
              if (phoneNumberController.text.isEmpty && state.profile.phoneNumber != null) {
                phoneNumberController.text = _stripLeadingCountry(state.profile.phoneNumber!);
              }
            }
          },
          // Котировка живёт в дочернем кубите, поэтому её состояние не мешает
          // OrderCreating/OrderCreated.
          child: BlocBuilder<DeliveryQuoteCubit, DeliveryQuoteState>(
            bloc: createOrderPage.quote,
            builder: (context, quoteState) {
              final loaded = quoteState is DeliveryQuoteLoaded ? quoteState : null;
              final method = _deliveryMethod;
              final deliveryPrice = method == null ? null : loaded?.priceFor(method);
              final statusText = _quoteStatusText(quoteState, l10n);
              final isQuoting = quoteState is DeliveryQuoteLoading;

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                child: Column(
                  children: [
                    DeliverySection(
                      row: _buildDeliveryRow(),
                      children: [
                        PostalField(controller: postalCodeController),
                        AddressField(controller: addressController),
                        HouseNumberField(controller: houseNumberController),
                        DeliveryMethodSelector(
                          selected: method,
                          onChanged: (m) => setState(() => _deliveryMethod = m),
                          branchPrice: loaded?.priceFor(DeliveryMethod.branch),
                          doorPrice: loaded?.priceFor(DeliveryMethod.door),
                          statusText: statusText,
                          onRetry: quoteState is DeliveryQuoteError ? createOrderPage.quote.retryQuote : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    RecipientSection(
                      nameController: whoTakesController,
                      phoneController: phoneNumberController,
                      // До отделения посылку получает сам покупатель, курьера
                      // никто не встречает.
                      nameLabel: method == DeliveryMethod.branch ? l10n.recipientNamePickupLabel : l10n.recipientNameCourierLabel,
                    ),
                    const SizedBox(height: 12),
                    PaymentMethodsSection(selected: _paymentMethod, onChanged: (m) => setState(() => _paymentMethod = m)),
                    const SizedBox(height: 12),
                    const BonusTicketsRow(ticketsToEarn: _kTicketsToEarn),
                    const SizedBox(height: 12),
                    OrderTotalSection(
                      cartModel: widget.cartModel,
                      deliveryPrice: deliveryPrice,
                      // Расчёт есть, но способ ещё не выбран — цена зависит
                      // от него, поэтому вместо суммы зовём выбрать.
                      deliveryStatusText: statusText ?? l10n.chooseAction,
                    ),
                    const SizedBox(height: 16),
                    // Пока считается доставка, кнопку не даём: иначе заказ
                    // уйдёт раньше, чем покупатель увидит цену.
                    BlocListener<CreateOrderCubit, CreateOrderState>(
                      bloc: createOrderPage,
                      listener: (context, state) {
                        orderLog.state('cubit state', state.runtimeType.toString());
                      },
                      child: MainButton(
                        onPressed: _submitting || isQuoting ? null : _onContinuePressed,
                        text: _submitting ? l10n.processingAction : l10n.continueAction,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: ConsentText(text: l10n.orderConsentText, offerLabel: l10n.orderConsentOffer, privacyLabel: l10n.orderConsentPrivacy),
                    ),
                  ],
                ),
              );
            },
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
