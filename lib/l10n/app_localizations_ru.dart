// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Bai Market';

  @override
  String get welcome => 'Добро пожаловать';

  @override
  String get login => 'Войти';

  @override
  String get register => 'Регистрация';

  @override
  String get email => 'Электронная почта';

  @override
  String get password => 'Пароль';

  @override
  String get confirmPassword => 'Подтвердите пароль';

  @override
  String get forgotPassword => 'Забыли пароль?';

  @override
  String get dontHaveAccount => 'Нет аккаунта?';

  @override
  String get alreadyHaveAccount => 'Уже есть аккаунт?';

  @override
  String get phone => 'Телефон';

  @override
  String get name => 'Имя';

  @override
  String get surname => 'Фамилия';

  @override
  String get phoneNumber => 'Номер телефона';

  @override
  String get enterName => 'Введите имя';

  @override
  String get enterSurname => 'Введите фамилию';

  @override
  String get enterPhone => 'Введите номер телефона';

  @override
  String get enterEmail => 'Введите email';

  @override
  String get enterPassword => 'Введите пароль';

  @override
  String get enterConfirmPassword => 'Подтвердите пароль';

  @override
  String get cart => 'Корзина';

  @override
  String get favorites => 'Избранное';

  @override
  String get profile => 'Профиль';

  @override
  String get settings => 'Настройки';

  @override
  String get language => 'Язык';

  @override
  String get notifications => 'Уведомления';

  @override
  String get logout => 'Выйти';

  @override
  String get catalog => 'Каталог';

  @override
  String get freeDelivery => 'Бесплатная доставка';

  @override
  String get deliveryAddress => 'Адрес доставки:';

  @override
  String get addressExample => 'Например: Ауезова 34';

  @override
  String get postalCode => 'Почтовый индекс';

  @override
  String get cardNumber => 'Номер карты';

  @override
  String get enterCardNumber => 'Введите номер карты';

  @override
  String get cvv => 'CVV';

  @override
  String get whoWillMeet => 'Кто встретит курьера?';

  @override
  String get nameExample => 'Например: Абзал';

  @override
  String get tryAgain => 'Попробовать снова';

  @override
  String get emptyCityList => 'Список городов пуст';

  @override
  String get productName => 'Название продукта';

  @override
  String get productDescription => 'Описание продукта';

  @override
  String get homeAddress => 'Адрес \"Дом\"';

  @override
  String postalIndex(String index) {
    return 'индекс: $index';
  }

  @override
  String get myAddresses => 'Мои адреса';

  @override
  String get orderHistory => 'История заказов';

  @override
  String get support => 'Поддержка';

  @override
  String get supportTitle => 'Поддержка';

  @override
  String get supportWorkingHours => 'Мы готовы помогать вам\nкаждый день с 9:00 - 22:00';

  @override
  String get whatsapp => 'WhatsApp';

  @override
  String get telegram => 'Telegram';

  @override
  String get faq => 'Часто задаваемые вопросы';

  @override
  String failedToOpen(String url) {
    return 'Не удалось открыть $url';
  }

  @override
  String get exitApp => 'Выход из приложения';

  @override
  String get exitConfirmation => 'Вы действительно хотите выйти из приложения?';

  @override
  String get cancel => 'Отмена';

  @override
  String get notInStock => 'Нет в продаже';

  @override
  String get youWon => 'Вы победили!';

  @override
  String get weWillContactYou => 'Скоро свяжемся с вами';

  @override
  String index(String index) {
    return 'Индекс: $index';
  }

  @override
  String price(String price) {
    return '$price ₸';
  }

  @override
  String oldPrice(String price) {
    return '$price ₸';
  }

  @override
  String get productDescriptionShort => 'Обеспечивает легкость и комфорт в макияжа весь...';

  @override
  String get home => 'Главная';

  @override
  String get products => 'товаров';

  @override
  String get more => 'Подробнее';

  @override
  String get in_sale => 'В продаже';

  @override
  String get not_in_sale => 'Нет в продаже';

  @override
  String get purchases => 'Покупку';

  @override
  String get orderAgain => 'Заказать снова';

  @override
  String get myPrizes => 'Мои призы';

  @override
  String get noPrizes => 'Нет призов';

  @override
  String get cartEmpty => 'В корзине пусто';

  @override
  String get addedItemsWillAppearHere => 'Добавленные товары будут\nотображаться тут';

  @override
  String get goToShopping => 'К покупкам';

  @override
  String get proceedToCheckout => 'Перейти к оформлению';

  @override
  String pricePerItem(String price) {
    return '$price тг/шт';
  }

  @override
  String get cannotAddMore => 'Больше нельзя добавить. Это максимум.';

  @override
  String get prize_goods => 'Призовые товары';

  @override
  String get number_of_tickets => 'Номер для участия в Акции';

  @override
  String get tickets => 'билеты';

  @override
  String get description => 'Описание';

  @override
  String get addToCart => 'В корзину';

  @override
  String get productOutOfStock => 'Товара нет в наличии!';

  @override
  String get productAddedToCart => 'Товар успешно сохранен в корзине!';

  @override
  String get goToCart => 'В корзину';

  @override
  String get showFirst => 'Вначале показывать';

  @override
  String get sortPopular => 'Популярное';

  @override
  String get sortCheap => 'Сначала дешевые';

  @override
  String get sortExpensive => 'Сначала дорогие';

  @override
  String get myData => 'Мои данные';

  @override
  String get save => 'Сохранить';

  @override
  String get deleteAccount => 'Удалить аккаунт';

  @override
  String get fillAllFields => 'Пожалуйста, заполните все поля';

  @override
  String profileUpdateError(String message) {
    return 'Ошибка при обновлении профиля: $message';
  }

  @override
  String error(String message) {
    return 'Ошибка: $message';
  }

  @override
  String get faqTicketAfterPayment => 'Как выдается номерок после оплаты?';

  @override
  String get faqTicketAfterPaymentAnswer => 'После оплаты номерок выдается автоматически. Вы можете увидеть его в разделе Мой профиль.';

  @override
  String get faqDeliveryMethod => 'Как осуществляется доставка?';

  @override
  String get faqDeliveryMethodAnswer => 'Доставка осуществляется через КазПочту. Вы получите уведомление, когда заказ будет отправлен.';

  @override
  String get faqDeliveryTime => 'Сколько времени занимает доставка?';

  @override
  String get faqDeliveryTimeAnswer => 'Обычно доставка занимает от 3 до 7 рабочих дней, в зависимости от вашего региона.';

  @override
  String get faqCancelOrder => 'Можно ли отменить заказ после оплаты?';

  @override
  String get faqCancelOrderAnswer => 'Да, вы можете отменить заказ до момента отправки. Для этого свяжитесь с нашей поддержкой.';

  @override
  String get faqTrackOrder => 'Как отследить мой заказ?';

  @override
  String get faqTrackOrderAnswer => 'После отправки вы получите трек-номер. Вы можете отследить посылку на сайте КазПочты или в разделе Мои заказы.';

  @override
  String get errorTitle => 'Ошибка';

  @override
  String get success => 'Успех!';

  @override
  String get orderDetails => 'О заказе';

  @override
  String get noData => 'Нет данных';

  @override
  String get recipient => 'Получатель:';

  @override
  String get noName => 'Нет имени';

  @override
  String get noPhone => 'Нет номера телефона';

  @override
  String get deliveryDate => 'Дата доставки:';

  @override
  String orderId(String id) {
    return 'ID Заказа: $id';
  }

  @override
  String get orderStatusPaymentPending => 'Ожидает оплаты';

  @override
  String get orderStatusProcessing => 'Формируется';

  @override
  String get orderStatusWay => 'В пути';

  @override
  String get orderStatusPickup => 'Готов к выдаче';

  @override
  String get orderStatusDelivered => 'Доставлен';

  @override
  String get orderStatusCanceled => 'Отменен';

  @override
  String get orderStatusAssembling => 'Собирается';

  @override
  String get orderStatusAbandoned => 'Отменен';

  @override
  String get orderStatusPaymentFailed => 'Ошибка оплаты';

  @override
  String get orderProcessingMessage => 'Ваши товары забронированы, заказ в обработке. Вам придет уведомление, когда заказ будет передан на сборку';

  @override
  String get ticketsWillBeAwarded => 'Будет начислено билетов';

  @override
  String get totalAmount => 'Общая сумма';

  @override
  String get items => 'Товары';

  @override
  String get discount => 'Скидка';

  @override
  String get promotionalNumbers => 'Акционные номера';

  @override
  String get delivery => 'Доставка';

  @override
  String get free => 'Бесплатно';

  @override
  String get total => 'Итого';

  @override
  String get paid => 'Оплачен';

  @override
  String get unpaid => 'Не оплачен';

  @override
  String get enterPhoneNumber => 'Введите \nномер телефона';

  @override
  String get weWillSendSms => 'Отправим СМС с кодом подтверждения';

  @override
  String get getCode => 'Получить код';

  @override
  String get termsAndPrivacy => 'Нажимая на кнопку \"Получить код\", вы принимаете пользовательское соглашение и политику конфиденциальности';

  @override
  String get enterCode => 'Введите код';

  @override
  String sentToNumber(String phoneNumber) {
    return 'Отправили его на номер \n+7 $phoneNumber';
  }

  @override
  String get signIn => 'Войти';

  @override
  String get market => 'Маркет';

  @override
  String get streams => 'Эфиры';

  @override
  String get orders => 'Заказы';

  @override
  String get searchHomeHint => 'Что вы искали?';

  @override
  String get all => 'Все';

  @override
  String get plusPrice => 'Plus пен алсаңыз';

  @override
  String sellerOrders(String count) {
    return '$count заказа';
  }

  @override
  String get reviews => 'Отзывы';

  @override
  String reviewsCount(String count) {
    return '$count отзывы';
  }

  @override
  String get readAll => 'Читать все';

  @override
  String get relatedProducts => 'Еще может подойти';

  @override
  String get buy => 'Купить';

  @override
  String get newTag => 'Новинка';

  @override
  String get hitTag => 'Хит';

  @override
  String get myTickets => 'Мой билеты';

  @override
  String get specifyDeliveryAddress => 'Укажите адрес доставки';

  @override
  String get myOrders => 'Мои заказы';

  @override
  String get orderStatus => 'Статус заказы';

  @override
  String get myCard => 'Мой карта';

  @override
  String get contacts => 'Контакты';

  @override
  String get inviteFriends => 'Приглашайте друзей';

  @override
  String get goToPayment => 'Перейти в оплате';

  @override
  String get clearCart => 'Очистить';

  @override
  String get youSaved => 'Вы экономили';

  @override
  String get recommended => 'Рекомендуем';

  @override
  String get notAvailable => 'Нет в наличии';

  @override
  String get defaultDescription => 'Высококачественный продукт, разработанный для ежедневного ухода. Тщательно подобранные компоненты обеспечивают эффективный результат. Подходит для всех типов кожи. Рекомендован специалистами.';

  @override
  String get liveNow => 'Сейчас в эфире';

  @override
  String get otpSubtitle => 'Мы отправили 4 значный код\nна ваш телефон';

  @override
  String get resendCode => 'Отправить код повторно';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get continueAction => 'Продолжить';

  @override
  String get notificationCategoryPurchase => 'Покупка';

  @override
  String get notificationCategoryDelivery => 'Доставка';

  @override
  String get notificationCategoryStream => 'Эфиры';

  @override
  String get notificationCategorySubscription => 'Подписка';

  @override
  String get noNotifications => 'Нет уведомлений';

  @override
  String get selectAddress => 'Выберите адрес';

  @override
  String get noSavedAddresses => 'У вас пока нет сохранённых адресов';

  @override
  String get addAddress => 'Добавить адрес';

  @override
  String get raffleTab => 'Розыгрыши';

  @override
  String get allShopsTab => 'Все магазины';

  @override
  String get wholeCatalogTab => 'Весь каталог';

  @override
  String get raffleDefaultTitle => 'Розыгрыш';

  @override
  String raffleDateLabel(String date) {
    return 'Дата: $date';
  }

  @override
  String get raffleDateTbd => 'Дата: уточняется';

  @override
  String raffleGiftsCount(int count) {
    return '$count подарков';
  }

  @override
  String get raffleGiftsAction => 'Обзор подарков';

  @override
  String get raffleGiftsTitle => 'Подарки розыгрыша';

  @override
  String get raffleGiftsEmpty => 'Подарков пока нет';

  @override
  String get raffleEmpty => 'Активных розыгрышей пока нет';

  @override
  String get raffleLoadError => 'Не удалось загрузить розыгрыш';

  @override
  String get raffleProductsEmpty => 'В этом розыгрыше пока нет товаров';

  @override
  String get sortDiscount => 'Скидка';

  @override
  String get baseAvatar => 'Базовый';

  @override
  String get selectAvatar => 'Выбрать';

  @override
  String get dateOfBirth => 'Дата рождения';

  @override
  String get birthDateHint => 'дд-мм-гггг';

  @override
  String get phoneNumberHint => '(000) - 00 - 00';

  @override
  String get addPhoto => 'Добавить фото';

  @override
  String get gallery => 'Галлерея';

  @override
  String get camera => 'Камера';

  @override
  String shareAppMessage(String link) {
    return 'Привет! Я использую это крутое приложение. Присоединяйся: $link';
  }

  @override
  String get shareAppError => 'Не удалось открыть окно \"Поделиться\"';

  @override
  String get ordersTabAll => 'Все';

  @override
  String get ordersTabActive => 'Активные';

  @override
  String get ordersTabCompleted => 'Завершенные';

  @override
  String get ordersTabReturn => 'Возврат';

  @override
  String get ordersEmptyTitle => 'Нет заказов';

  @override
  String get ordersEmptyMessage => 'Заказы будут отображаться тут';

  @override
  String get orderTagActive => 'Активный';

  @override
  String get orderTagCompleted => 'Завершен';

  @override
  String get orderTagReturn => 'Возврат';

  @override
  String get orderLeaveReview => 'Оставить отзыв';

  @override
  String get orderInTransitMessage => 'Ваш заказ передан на отправку. Немного терпения, товар уже в пути.';

  @override
  String get orderDeliveredMessage => 'Поздравляем! Курьер доставил заказ. Будем рады, если оцените нашу работу.';

  @override
  String get orderReturnMessage => 'Заказ был возвращен или отменен.';

  @override
  String priceTenge(String price) {
    return '$price₸';
  }

  @override
  String get favoritesEmptyTitle => 'Пока тут пусто';

  @override
  String get favoritesEmptySubtitle => 'Добавляйте товары в избранное, чтобы легко вернуться к ним позже!';

  @override
  String get goShopping => 'К покупкам';

  @override
  String get myCards => 'Мои карта';

  @override
  String get paymentCard => 'Платёжная карта';

  @override
  String get addCard => 'Добавить карта';

  @override
  String get cardsEmptyTitle => 'Нет карта';

  @override
  String get cardsEmptySubtitle => 'У вас пока нет сохранённых карт';

  @override
  String get contactsTitle => 'Контакты';

  @override
  String get callCenter => 'Колл-центр';

  @override
  String get callCenterSubtitle => 'Проконсультируем и поможем\nв оформлении заказа';

  @override
  String get acceptCallsHours => 'Принимаем звонки с 10:00 до 20:00';

  @override
  String get respondHours => 'Отвечаем с 10:00 до 20:00';

  @override
  String get writeOnWhatsapp => 'Написать на Whatsapp';

  @override
  String get writeOnTelegram => 'Написать на Telegram';

  @override
  String get deliverySectionTitle => 'Доставка';

  @override
  String get deliverySectionSubtitle => 'Победитли будеть на наш телеграм каналы';

  @override
  String get selfPickupSectionTitle => 'Адрес самавывоз';

  @override
  String get branches => 'Филиалы';

  @override
  String get loginRequired => 'Войдите в аккаунт';

  @override
  String get loginRequiredHint => 'Чтобы продолжить, войдите в свой аккаунт';

  @override
  String get addToCartFailed => 'Не удалось добавить в корзину';

  @override
  String get pullToRefresh => 'Потяните вниз, чтобы обновить';

  @override
  String get refreshing => 'Обновление…';

  @override
  String get removeFromCartFailed => 'Не удалось удалить из корзины';

  @override
  String get paymentAmountTitle => 'Сумма платежа:';

  @override
  String get paymentSumLabel => 'Сумма:';

  @override
  String get paymentCommissionLabel => 'Комиссия:';

  @override
  String get paymentTermsPart1 => 'Совершая платёж, вы автоматически';

  @override
  String get paymentTermsLinkText => 'соглашаетесь';

  @override
  String get paymentTermsPart2 => 'с условиями';

  @override
  String get payButton => 'Оплатить';

  @override
  String get fromTitle => 'Откуда';

  @override
  String get fromOtherCard => 'С другой карты';

  @override
  String get removeCardTitle => 'Удалить карту?';

  @override
  String get removeCardSubtitle => 'Вы точно хотите удалить эту карту';

  @override
  String get removeAction => 'Удалить';

  @override
  String get enterCardDataTitle => 'Введите данные карты';

  @override
  String get cardExpiryLabel => 'Срок действия';

  @override
  String get cardExpiryHint => 'Срок';

  @override
  String get cardCvvLabel => 'CVV-код';

  @override
  String get saveCardData => 'Сохранить данные карты';

  @override
  String get cardWarning => 'Убедитесь, что карта открыта для интернет-транзакций и лимита достаточно';

  @override
  String get orderAcceptedTitle => 'Ваш заказ принят!';

  @override
  String orderIdLabel(String id) {
    return 'ID заказа: $id';
  }

  @override
  String get receiptItemsLabel => 'Товары:';

  @override
  String get receiptSavedLabel => 'Сэкономлено:';

  @override
  String get receiptTicketsLabel => 'Билеты:';

  @override
  String get receiptPaymentMethodLabel => 'Способ оплаты:';

  @override
  String get viewOrderStatus => 'Посмотреть статус';

  @override
  String get viewersLabel => 'Зрителей';

  @override
  String get streamInactiveTitle => 'Стрим сейчас неактивен';

  @override
  String get streamInactiveSubtitle => 'Ожидайте начала трансляции';

  @override
  String get searchHint => 'Поиск товара…';

  @override
  String get searchPrompt => 'Начните вводить, чтобы найти товар';

  @override
  String get searchEmpty => 'Ничего не найдено';

  @override
  String get searchError => 'Не удалось выполнить поиск. Попробуйте ещё раз';

  @override
  String get onAirNow => 'Сейчас в эфире';

  @override
  String get giftButton => 'Подарок';

  @override
  String get commentInputHint => 'Введите комментарии...';

  @override
  String get inCart => 'В корзине';

  @override
  String get kaspiPayTitle => 'Оплата Kaspi';

  @override
  String kaspiAmountToPay(String amount) {
    return 'К оплате: $amount';
  }

  @override
  String get kaspiScanOrPay => 'Отсканируйте QR-код или нажмите «Оплатить», чтобы открыть Kaspi';

  @override
  String get kaspiWaitingPayment => 'Ожидаем оплату…';

  @override
  String get kaspiPaymentFailed => 'Оплата не прошла';

  @override
  String get kaspiLinkExpired => 'Срок действия ссылки истёк';

  @override
  String get kaspiPayAgain => 'Повторить оплату';
}
