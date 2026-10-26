// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kazakh (`kk`).
class AppLocalizationsKk extends AppLocalizations {
  AppLocalizationsKk([String locale = 'kk']) : super(locale);

  @override
  String get appName => 'hibai';

  @override
  String get welcome => 'Қош келдіңіз';

  @override
  String get login => 'Кіру';

  @override
  String get register => 'Тіркелу';

  @override
  String get email => 'Электрондық пошта';

  @override
  String get password => 'Құпия сөз';

  @override
  String get confirmPassword => 'Құпия сөзді растау';

  @override
  String get forgotPassword => 'Құпия сөзді ұмыттыңыз ба?';

  @override
  String get dontHaveAccount => 'Тіркелгіңіз жоқ па?';

  @override
  String get alreadyHaveAccount => 'Тіркелгіңіз бар ма?';

  @override
  String get phone => 'Телефон';

  @override
  String get name => 'Аты';

  @override
  String get surname => 'Тегі';

  @override
  String get phoneNumber => 'Телефон нөмірі';

  @override
  String get enterName => 'Атыңызды енгізіңіз';

  @override
  String get enterSurname => 'Тегіңізді енгізіңіз';

  @override
  String get enterPhone => 'Телефон нөміріңізді енгізіңіз';

  @override
  String get enterEmail => 'Email-діңізді енгізіңіз';

  @override
  String get enterPassword => 'Құпия сөзіңізді енгізіңіз';

  @override
  String get enterConfirmPassword => 'Құпия сөзіңізді растаңыз';

  @override
  String get cart => 'Себет';

  @override
  String get favorites => 'Таңдаулылар';

  @override
  String get profile => 'Профиль';

  @override
  String get settings => 'Баптаулар';

  @override
  String get language => 'Тіл';

  @override
  String get notifications => 'Хабарландырулар';

  @override
  String get logout => 'Шығу';

  @override
  String get catalog => 'Каталог';

  @override
  String get freeDelivery => 'Тегін жеткізу';

  @override
  String get deliveryAddress => 'Жеткізу мекенжайы:';

  @override
  String get addressExample => 'Мысалы: Әуезов 34';

  @override
  String get postalCode => 'Пошта индексі';

  @override
  String get cardNumber => 'Карта нөмірі';

  @override
  String get enterCardNumber => 'Карта нөмірін енгізіңіз';

  @override
  String get cvv => 'CVV';

  @override
  String get whoWillMeet => 'Кім қарсы алады (Толық аты-жөні)?';

  @override
  String get nameExample => 'Мысалы: Даниял Асылбеков';

  @override
  String get tryAgain => 'Қайталап көріңіз';

  @override
  String get emptyCityList => 'Қалалар тізімі бос';

  @override
  String get productName => 'Өнім атауы';

  @override
  String get productDescription => 'Өнім сипаттамасы';

  @override
  String get homeAddress => '\"Үй\" мекенжайы';

  @override
  String postalIndex(String index) {
    return 'индекс: $index';
  }

  @override
  String get myAddresses => 'Менің мекенжайларым';

  @override
  String get orderHistory => 'Тапсырыстар тарихы';

  @override
  String get support => 'Қолдау қызметі';

  @override
  String get supportTitle => 'Қолдау қызметі';

  @override
  String get supportWorkingHours => 'Біз сізге көмеkтесуге\nдайын әр күні 9:00 - 22:00';

  @override
  String get whatsapp => 'WhatsApp';

  @override
  String get telegram => 'Telegram';

  @override
  String get faq => 'Жиі қойылатын сұрақтар';

  @override
  String failedToOpen(String url) {
    return '$url ашу мүмкін емес';
  }

  @override
  String get exitApp => 'Қолданбадан шығу';

  @override
  String get exitConfirmation => 'Сіз шынымен қолданбадан шығғыңыз келе ме?';

  @override
  String get cancel => 'Бас тарту';

  @override
  String get notInStock => 'Сатылымда жоқ';

  @override
  String get youWon => 'Сіз жеңдіңіз!';

  @override
  String get weWillContactYou => 'Жақында сізбен байланысамыз';

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
  String get productDescriptionShort => 'Барлық макияжда жеңілдік пен ыңғайлылықты қамтамасыз етеді...';

  @override
  String get home => 'Басты бет';

  @override
  String get products => 'тауарлар';

  @override
  String get more => 'Толығырақ';

  @override
  String get in_sale => 'Сатылымда';

  @override
  String get not_in_sale => 'Сатылымда жоқ';

  @override
  String get purchases => 'Сатып алулар';

  @override
  String get orderAgain => 'Қайта тапсырыс беру';

  @override
  String get myPrizes => 'Менің ұтыстарым';

  @override
  String get noPrizes => 'Ұтыс жоқ';

  @override
  String get cartEmpty => 'Себет бос';

  @override
  String get addedItemsWillAppearHere => 'Қосылған тауарлар\nмұнда көрсетіледі';

  @override
  String get goToShopping => 'Сатып алуға өту';

  @override
  String get proceedToCheckout => 'Рәсімдеуге өту';

  @override
  String pricePerItem(String price) {
    return '$price тг/дана';
  }

  @override
  String get cannotAddMore => 'Қосымша қосу мүмкін емес. Бұл максимум.';

  @override
  String get prize_goods => 'Ұтыстың товарлары';

  @override
  String get number_of_tickets => 'Акцияға қатысу нөмірі';

  @override
  String get tickets => 'билеттер';

  @override
  String get description => 'Сипаттама';

  @override
  String get addToCart => 'Себетке қосу';

  @override
  String get productOutOfStock => 'Тауар қоймада жоқ!';

  @override
  String get productAddedToCart => 'Тауар сәтті себетке қосылды!';

  @override
  String get goToCart => 'Себетке өту';

  @override
  String get showFirst => 'Алдымен көрсету';

  @override
  String get sortPopular => 'Танымал';

  @override
  String get sortCheap => 'Арзан';

  @override
  String get sortExpensive => 'Қымбат';

  @override
  String get myData => 'Менің деректерім';

  @override
  String get save => 'Сақтау';

  @override
  String get deleteAccount => 'Тіркелгіні жою';

  @override
  String get fillAllFields => 'Барлық өрістерді толтырыңыз';

  @override
  String profileUpdateError(String message) {
    return 'Профильді жаңарту кезінде қате: $message';
  }

  @override
  String error(String message) {
    return 'Қате: $message';
  }

  @override
  String get faqTicketAfterPayment => 'Төлемнен кейін билет қалай беріледі?';

  @override
  String get faqTicketAfterPaymentAnswer => 'Төлемнен кейін билет автоматты түрде беріледі. Сіз оны Менің профилім бөлімінде көре аласыз.';

  @override
  String get faqDeliveryMethod => 'Жеткізу қалай жүргізіледі?';

  @override
  String get faqDeliveryMethodAnswer => 'Жеткізу ҚазПошта арқылы жүргізіледі. Тапсырыс жіберілген кезде сіз хабарландыру аласыз.';

  @override
  String get faqDeliveryTime => 'Жеткізу қанша уақыт алады?';

  @override
  String get faqDeliveryTimeAnswer => 'Жеткізу әдетте 3-7 жұмыс күні алады, сіздің аймағыңызға байланысты.';

  @override
  String get faqCancelOrder => 'Төлемнен кейін тапсырысты болдырмауға бола ма?';

  @override
  String get faqCancelOrderAnswer => 'Иә, тапсырысты жіберілгенге дейін болдыра аласыз. Ол үшін біздің қолдау қызметімен байланысыңыз.';

  @override
  String get faqTrackOrder => 'Тапсырысты қалай қадағалауға болады?';

  @override
  String get faqTrackOrderAnswer => 'Жіберілгеннен кейін сіз қадағалау нөмірін аласыз. Сіз пакетті ҚазПошта веб-сайтында немесе Менің тапсырыстарым бөлімінде қадағалай аласыз.';

  @override
  String get errorTitle => 'Қате';

  @override
  String get success => 'Сәтті!';

  @override
  String get orderDetails => 'Тапсырыс туралы';

  @override
  String get noData => 'Деректер жоқ';

  @override
  String get recipient => 'Алушы:';

  @override
  String get noName => 'Аты жоқ';

  @override
  String get noPhone => 'Телефон нөмірі жоқ';

  @override
  String get deliveryDate => 'Жеткізу күні:';

  @override
  String orderId(String id) {
    return 'Тапсырыс ID: $id';
  }

  @override
  String get orderStatusPaymentPending => 'Төлем күтілуде';

  @override
  String get orderStatusProcessing => 'Өңделуде';

  @override
  String get orderStatusWay => 'Жолда';

  @override
  String get orderStatusPickup => 'Бөлімшеде күтуде';

  @override
  String get orderStatusDelivered => 'Алынды';

  @override
  String get orderStatusCanceled => 'Бас тартылды';

  @override
  String get orderStatusAssembling => 'Тапсырыс жиналуда';

  @override
  String get orderStatusAbandoned => 'Бас тартылды';

  @override
  String get orderStatusPaymentFailed => 'Төлем қатесі';

  @override
  String get orderProcessingMessage => 'Сіздің тауарларыңыз брондалды, тапсырыс өңделуде. Тапсырыс жинауға берілгенде сіз хабарландыру аласыз';

  @override
  String get ticketsWillBeAwarded => 'Билеттер есептеледі';

  @override
  String get totalAmount => 'Жалпы сома';

  @override
  String get items => 'Тауарлар';

  @override
  String get discount => 'Жеңілдік';

  @override
  String get promotionalNumbers => 'Акциялық нөмірлер';

  @override
  String get delivery => 'Жеткізу';

  @override
  String get free => 'Тегін';

  @override
  String get total => 'Барлығы';

  @override
  String get paid => 'Төленді';

  @override
  String get unpaid => 'Төленбеді';

  @override
  String get enterPhoneNumber => 'Телефон нөміріңізді \nенгізіңіз';

  @override
  String get weWillSendSms => 'Растау коды бар SMS жібереміз';

  @override
  String get getCode => 'Код алу';

  @override
  String get orderConsentText => 'Түймені басу арқылы сіз Оферта шарттарымен және Құпиялылық саясатымен келісесіз';

  @override
  String get orderConsentOffer => 'Оферта шарттарымен';

  @override
  String get orderConsentPrivacy => 'Құпиялылық саясатымен';

  @override
  String get termsAndPrivacy => '\"Код алу\" түймесін басу арқылы сіз пайдалану шарттарын және құпиялылық саясатын қабылдайсыз';

  @override
  String get userAgreement => 'пайдалану шарттарын';

  @override
  String get privacyPolicy => 'құпиялылық саясатын';

  @override
  String get greeting => 'Сәлеметсіз бе!';

  @override
  String get cannotLogin => 'Кіре алмайсыз ба?';

  @override
  String get createPinTitle => 'PIN-код ойлап табыңыз';

  @override
  String get confirmPinTitle => 'PIN-кодты қайталаңыз';

  @override
  String get pinMismatch => 'PIN-кодтар сәйкес келмейді';

  @override
  String get wrongPin => 'PIN-код қате';

  @override
  String get fillInData => 'Толтырыңыз';

  @override
  String get selectCity => 'Қаланы таңдаңыз';

  @override
  String get enterCode => 'Кодты енгізіңіз';

  @override
  String sentToNumber(String phoneNumber) {
    return 'Оны +7 $phoneNumber нөміріне жібердік \n';
  }

  @override
  String get signIn => 'Кіру';

  @override
  String get market => 'Маркет';

  @override
  String get streams => 'Эфирлер';

  @override
  String get orders => 'Тапсырыстар';

  @override
  String get searchHomeHint => 'Не іздедіңіз?';

  @override
  String get all => 'Барлығы';

  @override
  String get plusPrice => 'Plus-пен алсаңыз';

  @override
  String sellerOrders(String count) {
    return '$count тапсырыс';
  }

  @override
  String get reviews => 'Пікірлер';

  @override
  String reviewsCount(String count) {
    return '$count пікір';
  }

  @override
  String get readAll => 'Барлығын оқу';

  @override
  String get relatedProducts => 'Сізге ұнауы мүмкін';

  @override
  String get buy => 'Сатып алу';

  @override
  String get newTag => 'Жаңа';

  @override
  String get hitTag => 'Хит';

  @override
  String get myTickets => 'Менің билеттерім';

  @override
  String get specifyDeliveryAddress => 'Жеткізу мекенжайын көрсетіңіз';

  @override
  String get myOrders => 'Менің тапсырыстарым';

  @override
  String get orderStatus => 'Тапсырыс күйі';

  @override
  String get myCard => 'Менің картам';

  @override
  String get contacts => 'Байланыстар';

  @override
  String get sattyJuldyz => 'Satty juldyz';

  @override
  String get techSupport => 'Тех көмек';

  @override
  String get inviteFriends => 'Достарыңызды шақырыңыз';

  @override
  String get goToPayment => 'Төлемге өту';

  @override
  String get clearCart => 'Тазалау';

  @override
  String get youSaved => 'Сіз үнемдедіңіз';

  @override
  String get recommended => 'Ұсынамыз';

  @override
  String get notAvailable => 'Қолжетімсіз';

  @override
  String get defaultDescription => 'Күнделікті күтімге арналған жоғары сапалы өнім. Мұқият таңдалған компоненттер тиімді нәтиже береді. Барлық тері түрлеріне жарамды. Мамандар ұсынған өнім.';

  @override
  String get liveNow => 'Қазір эфирде';

  @override
  String get otpSubtitle => 'Телефоныңызға 4 таңбалы код\nжібердік';

  @override
  String get resendCode => 'Кодты қайта жіберу';

  @override
  String get confirm => 'Растау';

  @override
  String get continueAction => 'Жалғастыру';

  @override
  String get notificationCategoryPurchase => 'Сатып алу';

  @override
  String get notificationCategoryDelivery => 'Жеткізу';

  @override
  String get notificationCategoryStream => 'Эфирлер';

  @override
  String get notificationCategorySubscription => 'Жазылым';

  @override
  String get noNotifications => 'Хабарландырулар жоқ';

  @override
  String get selectAddress => 'Мекенжай таңдаңыз';

  @override
  String get noSavedAddresses => 'Сізде сақталған мекенжайлар жоқ';

  @override
  String get deliveryAddressesTitle => 'Жеткізу мекенжайлары';

  @override
  String get deliveryAddressTitle => 'Жеткізу мекенжайы';

  @override
  String get addMoreAddress => 'Тағы мекенжай қосу';

  @override
  String get saveAddress => 'Мекенжайды сақтау';

  @override
  String get newAddress => 'Жаңа мекенжай';

  @override
  String addressLabeled(String label) {
    return '«$label» мекенжайы';
  }

  @override
  String get addressAdded => 'Мекенжай сәтті қосылды';

  @override
  String get addressDeleted => 'Мекенжай жойылды';

  @override
  String get deleteAddressTitle => 'Мекенжайды жою керек пе?';

  @override
  String get deleteAddressMessage => 'Осы мекенжайды жойғыңыз келетініне сенімдісіз бе?';

  @override
  String get deleteAction => 'Жою';

  @override
  String get addAction => 'Қосу';

  @override
  String get savingInProgress => 'Сақталуда...';

  @override
  String get addressNameLabel => 'Мекенжай атауы';

  @override
  String get addressNameHint => 'Мысалы: Үй немесе жұмыс';

  @override
  String get enterAddressName => 'Атауын енгізіңіз';

  @override
  String get streetAndHouseHint => 'Көше және үй нөмірі';

  @override
  String get enterAddressLine => 'Мекенжайды енгізіңіз';

  @override
  String get apartmentLabel => 'Пәтер';

  @override
  String get entranceLabel => 'Кіреберіс';

  @override
  String get floorLabel => 'Қабат';

  @override
  String get postalIndexHint => 'Индекс';

  @override
  String get enterPostalIndex => 'Индексті енгізіңіз';

  @override
  String get selectCityFirst => 'Қаланы таңдаңыз';

  @override
  String get selectRegion => 'Аймақты таңдаңыз';

  @override
  String get addressesLoadError => 'Мекенжайларды жүктеу қатесі';

  @override
  String get addressAddError => 'Мекенжай қосу қатесі';

  @override
  String get addressSaveError => 'Мекенжайды сақтау мүмкін болмады';

  @override
  String get addressDeleteError => 'Мекенжайды жою қатесі';

  @override
  String get addAddress => 'Мекенжай қосу';

  @override
  String get raffleTab => 'Ұтыстар';

  @override
  String get allShopsTab => 'Барлық дүкендер';

  @override
  String get wholeCatalogTab => 'Барлық каталог';

  @override
  String get catalogTileLottery => 'Ұтыс\nтауарлары';

  @override
  String get catalogTileDiscount => 'Жеңілдікті\nтауарлар';

  @override
  String get catalogTileMakeup => 'Макияжға';

  @override
  String get catalogTilePerfume => 'Парфюмерия';

  @override
  String get catalogTileBodyCare => 'Денеге\nкүтім';

  @override
  String get catalogTileHairCare => 'Шашқа\nкүтім';

  @override
  String get catalogTileCosmeticSets => 'Косметика\nжинақтары';

  @override
  String get catalogTileFaceCare => 'Бетке\nкүтім';

  @override
  String get catalogTileSunCare => 'Күннен\nқорғау';

  @override
  String get catalogTileHygiene => 'Жеке\nгигиена';

  @override
  String get catalogTileOralCare => 'Ауыз қуысын\nкүту';

  @override
  String get raffleDefaultTitle => 'Ұтыс';

  @override
  String raffleDateLabel(String date) {
    return 'Күні: $date';
  }

  @override
  String get raffleDateTbd => 'Күні: нақтыланады';

  @override
  String raffleGiftsCount(int count) {
    return '$count сыйлық';
  }

  @override
  String get raffleGiftsAction => 'Ұтыстарға шолу';

  @override
  String get raffleGiftsTitle => 'Ұтыс сыйлықтары';

  @override
  String get raffleGiftsEmpty => 'Сыйлықтар әзірге жоқ';

  @override
  String get raffleEmpty => 'Белсенді ұтыстар әзірге жоқ';

  @override
  String get raffleLoadError => 'Ұтысты жүктеу мүмкін болмады';

  @override
  String get raffleProductsEmpty => 'Бұл ұтыста әзірге тауарлар жоқ';

  @override
  String get sortDiscount => 'Жеңілдік';

  @override
  String get baseAvatar => 'Негізгі';

  @override
  String get selectAvatar => 'Таңдау';

  @override
  String get dateOfBirth => 'Туған күні';

  @override
  String get birthDateHint => 'кк-аа-жжжж';

  @override
  String get phoneNumberHint => '(000) - 00 - 00';

  @override
  String get addPhoto => 'Фото қосу';

  @override
  String get gallery => 'Галерея';

  @override
  String get camera => 'Камера';

  @override
  String shareAppMessage(String link) {
    return 'Сәлем! Мен мына керемет қосымшаны қолданамын. Қосыл: $link';
  }

  @override
  String get shareAppError => '\"Бөлісу\" терезесін ашу мүмкін болмады';

  @override
  String get ordersTabAll => 'Барлығы';

  @override
  String get ordersTabActive => 'Белсенді';

  @override
  String get ordersTabCompleted => 'Аяқталған';

  @override
  String get ordersTabReturn => 'Қайтарылған';

  @override
  String get ordersEmptyTitle => 'Тапсырыс жоқ';

  @override
  String get ordersEmptyMessage => 'Тапсырыстар осында көрсетіледі';

  @override
  String get orderTagActive => 'Белсенді';

  @override
  String get orderTagCompleted => 'Аяқталды';

  @override
  String get orderTagReturn => 'Қайтарылды';

  @override
  String get orderLeaveReview => 'Пікір қалдыру';

  @override
  String get orderInTransitMessage => 'Тапсырысыңыз жіберуге берілді. Сәл сабыр сақтаңыз, тауар жолда.';

  @override
  String get orderDeliveredMessage => 'Құттықтаймыз! Курьер тапсырысты жеткізді. Жұмысымызды бағаласаңыз, қуанышты боламыз.';

  @override
  String get orderReturnMessage => 'Тапсырыс қайтарылды немесе бас тартылды.';

  @override
  String priceTenge(String price) {
    return '$price₸';
  }

  @override
  String get favoritesEmptyTitle => 'Әзірге бос';

  @override
  String get favoritesEmptySubtitle => 'Кейін оңай оралу үшін тауарларды таңдаулыға қосыңыз!';

  @override
  String get goShopping => 'Сатып алуға';

  @override
  String get myCards => 'Менің карталарым';

  @override
  String get paymentCard => 'Төлем картасы';

  @override
  String get addCard => 'Карта қосу';

  @override
  String get cardsEmptyTitle => 'Карта жоқ';

  @override
  String get cardsEmptySubtitle => 'Сізде әлі сақталған карталар жоқ';

  @override
  String get contactsTitle => 'Байланыстар';

  @override
  String get callCenter => 'Колл-орталық';

  @override
  String get callCenterSubtitle => 'Кеңес береміз және тапсырыс\nресімдеуге көмектесеміз';

  @override
  String get acceptCallsHours => 'Қоңырауларды 10:00-ден 20:00-ге дейін қабылдаймыз';

  @override
  String get respondHours => '10:00-ден 20:00-ге дейін жауап береміз';

  @override
  String get writeOnWhatsapp => 'Whatsapp-қа жазу';

  @override
  String get writeOnTelegram => 'Telegram-ға жазу';

  @override
  String get deliverySectionTitle => 'Жеткізу';

  @override
  String get deliverySectionSubtitle => 'Жаңартулар телеграм каналымызда';

  @override
  String get selfPickupSectionTitle => 'Өзі алу мекенжайы';

  @override
  String get branches => 'Филиалдар';

  @override
  String get loginRequired => 'Аккаунтқа кіріңіз';

  @override
  String get loginRequiredHint => 'Жалғастыру үшін аккаунтыңызға кіріңіз';

  @override
  String get addToCartFailed => 'Себетке қосу мүмкін болмады';

  @override
  String get pullToRefresh => 'Жаңарту үшін төмен тартыңыз';

  @override
  String get refreshing => 'Жаңартылуда…';

  @override
  String get removeFromCartFailed => 'Себеттен жою мүмкін болмады';

  @override
  String get paymentAmountTitle => 'Төлем сомасы:';

  @override
  String get paymentSumLabel => 'Сома:';

  @override
  String get paymentCommissionLabel => 'Комиссия:';

  @override
  String get paymentTermsPart1 => 'Төлем жүргізе, сіз автоматты түрде';

  @override
  String get paymentTermsLinkText => 'шарттармен';

  @override
  String get paymentTermsPart2 => 'келісесіз';

  @override
  String get payButton => 'Төлем жасау';

  @override
  String get fromTitle => 'Қайдан';

  @override
  String get fromOtherCard => 'Басқа картадан';

  @override
  String get removeCardTitle => 'Картаны жою керек пе?';

  @override
  String get removeCardSubtitle => 'Осы картаны жоюды шынымен қалайсыз ба';

  @override
  String get removeAction => 'Жою';

  @override
  String get enterCardDataTitle => 'Карта деректерін енгізіңіз';

  @override
  String get cardExpiryLabel => 'Жарамдылық мерзімі';

  @override
  String get cardExpiryHint => 'Мерзім';

  @override
  String get cardCvvLabel => 'CVV-код';

  @override
  String get saveCardData => 'Карта деректерін сақтау';

  @override
  String get cardWarning => 'Карта интернет-транзакцияларға ашық және лимит жеткілікті екеніне көз жеткізіңіз';

  @override
  String get orderAcceptedTitle => 'Сіздің заказыңыз қабылданды!';

  @override
  String orderIdLabel(String id) {
    return 'Тапсырыс ID: $id';
  }

  @override
  String get receiptItemsLabel => 'Тауарлар:';

  @override
  String get receiptSavedLabel => 'Үнемделді:';

  @override
  String get receiptTicketsLabel => 'Билеттер:';

  @override
  String get receiptPaymentMethodLabel => 'Төлем тәсілі:';

  @override
  String get viewOrderStatus => 'Күйді көру';

  @override
  String get viewersLabel => 'Көрермендер';

  @override
  String get streamInactiveTitle => 'Стрим қазір белсенді емес';

  @override
  String get streamInactiveSubtitle => 'Тарату басталуын күтіңіз';

  @override
  String get searchHint => 'Тауар іздеу…';

  @override
  String get searchPrompt => 'Тауар табу үшін теруді бастаңыз';

  @override
  String get searchEmpty => 'Ештеңе табылмады';

  @override
  String get searchError => 'Іздеу орындалмады. Қайталап көріңіз';

  @override
  String get onAirNow => 'Қазір эфирде';

  @override
  String get giftButton => 'Сыйлық';

  @override
  String get commentInputHint => 'Пікір жазыңыз...';

  @override
  String get inCart => 'Себетте';

  @override
  String get kaspiPayTitle => 'Kaspi төлемі';

  @override
  String kaspiAmountToPay(String amount) {
    return 'Төлеуге: $amount';
  }

  @override
  String get kaspiScanOrPay => 'QR-кодты сканерлеңіз немесе Kaspi ашу үшін «Төлеу» түймесін басыңыз';

  @override
  String get kaspiWaitingPayment => 'Төлемді күтудеміз…';

  @override
  String get kaspiPaymentFailed => 'Төлем өтпеді';

  @override
  String get kaspiLinkExpired => 'Сілтеме мерзімі аяқталды';

  @override
  String get kaspiPayAgain => 'Қайта төлеу';

  @override
  String sellerRaffleDate(String date) {
    return 'Ұтыс: $date';
  }

  @override
  String get sellersEmpty => 'Әзірге дүкендер жоқ';

  @override
  String get sellersLoadError => 'Дүкендерді жүктеу мүмкін болмады';

  @override
  String get sellerProductsEmpty => 'Бұл дүкенде әзірге тауар жоқ';

  @override
  String get sellerNotFound => 'Дүкен қолжетімсіз';

  @override
  String get sellerStoreTitleFallback => 'Дүкен';

  @override
  String ticketsBadge(String count) {
    return '+$count';
  }

  @override
  String get productUnavailable => 'Тауар қолжетімсіз';

  @override
  String get plusPriceActive => 'Plus бағаңыз';

  @override
  String get reviewsEmpty => 'Әзірге пікірлер жоқ';

  @override
  String get reviewAnonymous => 'Сатып алушы';

  @override
  String get reviewComposerHint => 'Тауар туралы әсеріңізбен бөлісіңіз';

  @override
  String get reviewSend => 'Жіберу';

  @override
  String get reviewSubmitted => 'Пікіріңізге рахмет!';

  @override
  String get reviewAlreadyLeft => 'Сіз бұл тауарға пікір қалдырғансыз';

  @override
  String get reviewTooManyRequests => 'Тым көп әрекет. Бір минуттан кейін қайталаңыз';

  @override
  String get reviewSubmitError => 'Пікірді жіберу мүмкін болмады';

  @override
  String get reviewsLoadError => 'Пікірлерді жүктеу мүмкін болмады';

  @override
  String shareProductMessage(String name, String price) {
    return '$name — $price. Bai Market-тен таптым.';
  }

  @override
  String shareProductMessageNoPrice(String name) {
    return '$name. Bai Market-тен таптым.';
  }

  @override
  String cartItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count тауар',
    );
    return '$_temp0';
  }

  @override
  String get checkoutShort => 'Рәсімдеу';

  @override
  String get cartClearFailed => 'Себетті тазалау мүмкін болмады';

  @override
  String get cartNotEnoughStock => 'Қорда тауар жеткіліксіз';

  @override
  String get cartQuantityChangeFailed => 'Санын өзгерту мүмкін болмады — тауар себеттен жойылды, қайта қосыңыз';

  @override
  String cartItemRemovedByStock(String name) {
    return '«$name» бітті және себеттен жойылды';
  }

  @override
  String cartItemPriceChanged(String name) {
    return '«$name» бағасы өзгерді';
  }

  @override
  String cartItemQuantityReduced(String name, String quantity) {
    return '«$name» саны $quantity дейін азайтылды';
  }

  @override
  String get cartRefreshFailed => 'Себетті жаңарту мүмкін болмады';

  @override
  String get pushPermissionTitle => 'Хабарламаларды қосыңыз';

  @override
  String get pushPermissionBody => 'Тапсырыс күйі, ұтыс нәтижелері және жаңалықтар туралы хабарлаймыз';

  @override
  String get pushPermissionAllow => 'Қосу';

  @override
  String get pushPermissionLater => 'Кейінірек';

  @override
  String get pushDisabledBanner => 'Хабарламалар өшірілген';

  @override
  String get pushEnableAction => 'Қосу';

  @override
  String get notificationsSettingsTitle => 'Хабарламалар';

  @override
  String get notificationsOn => 'Қосылған';

  @override
  String get notificationsOff => 'Өшірілген';

  @override
  String get notificationsLoadError => 'Хабарламаларды жүктеу мүмкін болмады';

  @override
  String get commonCancel => 'Бас тарту';

  @override
  String get addedToCart => 'Себетке қосылды';

  @override
  String get outOfStock => 'Қоймада жоқ';

  @override
  String get pullToRefreshHint => 'Жаңарту үшін төмен тартыңыз';

  @override
  String get streamsLoadError => 'Эфирлерді жүктеу мүмкін болмады';

  @override
  String get streamsEmptyTitle => 'Қазір эфир жоқ';

  @override
  String get streamsEmptySubtitle => 'Сәлден кейін қараңыз';

  @override
  String get streamErrorGeneric => 'Бірдеңе дұрыс болмады';

  @override
  String get streamEndedTitle => 'Эфир аяқталды';

  @override
  String get streamEndedSubtitle => 'Басқа эфирді таңдаңыз';

  @override
  String get streamReconnecting => 'Қайта қосылудамыз…';

  @override
  String get streamConnectionLost => 'Байланыс үзілді';

  @override
  String get streamRetry => 'Қайталау';

  @override
  String get streamChatTooLong => 'Хабарлама тым ұзын';

  @override
  String get streamChatRateLimited => 'Хабарлама тым көп, сәл күте тұрыңыз';

  @override
  String get streamProductsTitle => 'Эфирдегі тауарлар';

  @override
  String get streamGiftsTitle => 'Сыйлықтар';

  @override
  String get pinnedProductBadge => 'Эфирде';

  @override
  String get streamHostCameraPaused => 'Сатушы камераны өшірді';

  @override
  String get streamStartCta => 'Эфир бастау';

  @override
  String get streamResumeCta => 'Эфиріңізге оралу';

  @override
  String get startStreamSheetTitle => 'Жаңа эфир';

  @override
  String get startStreamTitleLabel => 'Эфир атауы';

  @override
  String get startStreamTitleHint => 'Мысалы: Кроссовкалар жеңілдігі';

  @override
  String get startStreamTitleTooShort => 'Ұзынырақ атау енгізіңіз';

  @override
  String get startStreamSubmit => 'Бастау';

  @override
  String get startStreamFailed => 'Эфирді бастау мүмкін болмады';

  @override
  String get streamAccessDenied => 'Эфирлер қолжетімсіз, қолдау қызметіне хабарласыңыз';

  @override
  String get streamAlreadyLiveTitle => 'Сізде эфир жүріп жатыр';

  @override
  String get streamAlreadyLiveMessage => 'Бір мезгілде бір ғана эфир жүргізуге болады. Ағымдағысын аяқтаңыз немесе көрермен ретінде ашыңыз.';

  @override
  String get streamEndAndRestart => 'Аяқтап, қайта бастау';

  @override
  String get streamOpenAsViewer => 'Көрермен ретінде ашу';

  @override
  String get streamStopConfirmTitle => 'Эфирді аяқтайсыз ба?';

  @override
  String get streamStopConfirmAction => 'Аяқтау';

  @override
  String get hostCameraPaused => 'Камера өшірулі';

  @override
  String get hostPickProductTitle => 'Тауарды көрсету';

  @override
  String get hostPinProduct => 'Көрсету';

  @override
  String get hostUnpinProduct => 'Тауарды экраннан алу';

  @override
  String get hostNoProducts => 'Әзірге тауар жоқ';

  @override
  String get hostPermissionDeniedTitle => 'Камера мен микрофонға рұқсат керек';

  @override
  String get hostPermissionDeniedMessage => 'Эфирге шығу үшін параметрлерде рұқсат беріңіз.';

  @override
  String get hostOpenSettings => 'Параметрлер';

  @override
  String get storyOpenProduct => 'Тауарға өту';

  @override
  String stockLeft(int count) {
    return '$count дана қалды!';
  }

  @override
  String get updateForcedTitle => 'Жаңарту қажет';

  @override
  String get updateForcedMessage => 'Bai Market қолданбасының бұл нұсқасына қолдау көрсетілмейді. Соңғы нұсқаны орнатыңыз — бұл бір минуттан аз уақыт алады.';

  @override
  String get updateRecommendedTitle => 'Жаңа нұсқа шықты';

  @override
  String get updateRecommendedMessage => 'Біз жаңа мүмкіндіктер қостық және бірнеше ақауды түзеттік. Жаңарту бір минуттан аз уақыт алады.';

  @override
  String get updateNow => 'Жаңарту';

  @override
  String get updateLater => 'Кейінірек';

  @override
  String get updateWhatsNew => 'Не жаңалық';

  @override
  String profileVersion(String version) {
    return 'Нұсқа: $version';
  }

  @override
  String updateVersionBadge(String version) {
    return '$version нұсқасы';
  }

  @override
  String get updateStoreOpenFailed => 'Қолданбалар дүкенін ашу мүмкін болмады. Қайталап көріңіз.';

  @override
  String get checkoutTitle => 'Тапсырысты рәсімдеу';

  @override
  String get savedAddressTitle => 'Сақталған мекенжай';

  @override
  String get selectSavedAddressFirst => 'Сақталған мекенжайды таңдаңыз';

  @override
  String get chooseAction => 'таңдау';

  @override
  String get changeAction => 'Өзгерту';

  @override
  String get addressFallbackTitle => 'Мекенжай';

  @override
  String branchWithAddress(String address) {
    return 'Филиал: $address';
  }

  @override
  String get cityFallbackName => 'Қала';

  @override
  String get recipientNameCourierLabel => 'Кім қарсы алады (Аты-жөні)';

  @override
  String get recipientNamePickupLabel => 'Кім алып кетеді (Аты-жөні)';

  @override
  String get recipientNameHint => 'Мысалы: Асылбек Даниял';

  @override
  String get processingAction => 'Өңделуде…';

  @override
  String get kaspiPaymentStartFailed => 'Kaspi төлемін бастау мүмкін болмады';

  @override
  String get paymentMethodsTitle => 'Төлем әдістері';

  @override
  String get deliveryByCourier => 'Курьермен';

  @override
  String get deliverySelfPickup => 'Өзі алып кету';

  @override
  String get filialDistrict => 'Бостандық ауданы';

  @override
  String get filialAddressLine => 'Абдулла Розыбакиев көшесі, 112';

  @override
  String get deliveryMethodBranch => 'Қазпошта бөлімшесіне дейін';

  @override
  String get deliveryMethodBranchHint => 'Трек-нөмір бойынша поштадан аласыз';

  @override
  String get deliveryMethodDoor => 'Есікке дейін';

  @override
  String get deliveryMethodDoorHint => 'Go Post курьері үйге жеткізеді';

  @override
  String get houseNumberLabel => 'Үй және пәтер';

  @override
  String get houseNumberHint => '150, пәтер 25';

  @override
  String get enterHouseNumber => 'Үй мен пәтерді көрсетіңіз';

  @override
  String get postalCodeInvalidLength => 'Индекс 6 саннан тұруы керек';

  @override
  String get enterPostalForDelivery => 'Жеткізу құнын білу үшін индексті енгізіңіз';

  @override
  String get selectAddressForDelivery => 'Жеткізу құнын білу үшін мекенжайды таңдаңыз';

  @override
  String get deliveryPriceCalculating => 'Есептеп жатырмыз…';

  @override
  String get amountToPay => 'Төлеуге';

  @override
  String get trackingNumberLabel => 'Трек-нөмір';

  @override
  String get trackOnKazpost => 'post.kz сайтында бақылау';

  @override
  String get trackingNumberCopied => 'Трек-нөмір көшірілді';

  @override
  String get orderStatusPickupKazpostMessage => 'Сәлемдеме Қазпошта бөлімшесінде күтіп тұр. Оны трек-нөмір бойынша алыңыз';

  @override
  String get deliveryQuoteFailed => 'Жеткізуді есептеу мүмкін болмады. Қайталап көріңіз';
}
