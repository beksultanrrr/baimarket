// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'hibai';

  @override
  String get welcome => 'Welcome';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get phone => 'Phone';

  @override
  String get name => 'Name';

  @override
  String get surname => 'Surname';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get enterName => 'Enter your name';

  @override
  String get enterSurname => 'Enter your surname';

  @override
  String get enterPhone => 'Enter your phone number';

  @override
  String get enterEmail => 'Enter your email';

  @override
  String get enterPassword => 'Enter your password';

  @override
  String get enterConfirmPassword => 'Confirm your password';

  @override
  String get cart => 'Cart';

  @override
  String get favorites => 'Favorites';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get notifications => 'Notifications';

  @override
  String get logout => 'Logout';

  @override
  String get catalog => 'Catalog';

  @override
  String get freeDelivery => 'Free delivery';

  @override
  String get deliveryAddress => 'Delivery Address:';

  @override
  String get addressExample => 'Example: Auezova 34';

  @override
  String get postalCode => 'Postal Code';

  @override
  String get cardNumber => 'Card number';

  @override
  String get enterCardNumber => 'Enter card number';

  @override
  String get cvv => 'CVV';

  @override
  String get whoWillMeet => 'Who will meet the courier?';

  @override
  String get nameExample => 'Example: Abzal';

  @override
  String get tryAgain => 'Try again';

  @override
  String get emptyCityList => 'City list is empty';

  @override
  String get productName => 'Product name';

  @override
  String get productDescription => 'Product description';

  @override
  String get homeAddress => 'Home Address';

  @override
  String postalIndex(String index) {
    return 'Postal index: $index';
  }

  @override
  String get myAddresses => 'My Addresses';

  @override
  String get orderHistory => 'Order History';

  @override
  String get support => 'Support';

  @override
  String get supportTitle => 'Support';

  @override
  String get supportWorkingHours => 'We are ready to help you\nevery day from 9:00 - 22:00';

  @override
  String get whatsapp => 'WhatsApp';

  @override
  String get telegram => 'Telegram';

  @override
  String get faq => 'Frequently Asked Questions';

  @override
  String failedToOpen(String url) {
    return 'Failed to open $url';
  }

  @override
  String get exitApp => 'Exit Application';

  @override
  String get exitConfirmation => 'Are you sure you want to exit the application?';

  @override
  String get cancel => 'Cancel';

  @override
  String get notInStock => 'Out of stock';

  @override
  String get youWon => 'You won!';

  @override
  String get weWillContactYou => 'We will contact you soon';

  @override
  String index(String index) {
    return 'Index: $index';
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
  String get productDescriptionShort => 'Provides ease and comfort in makeup all...';

  @override
  String get home => 'Home';

  @override
  String get products => 'products';

  @override
  String get more => 'More';

  @override
  String get in_sale => 'In Sale';

  @override
  String get not_in_sale => 'Not in sale';

  @override
  String get purchases => 'Purchases';

  @override
  String get orderAgain => 'Order again';

  @override
  String get myPrizes => 'My prizes';

  @override
  String get noPrizes => 'No prizes';

  @override
  String get cartEmpty => 'Cart is empty';

  @override
  String get addedItemsWillAppearHere => 'Added items will appear here';

  @override
  String get goToShopping => 'Go shopping';

  @override
  String get proceedToCheckout => 'Proceed to checkout';

  @override
  String pricePerItem(String price) {
    return '$price ₸/item';
  }

  @override
  String get cannotAddMore => 'Cannot add more. This is the maximum.';

  @override
  String get prize_goods => 'Prize goods';

  @override
  String get number_of_tickets => 'Number for participation';

  @override
  String get tickets => 'tickets';

  @override
  String get description => 'Description';

  @override
  String get addToCart => 'Add to Cart';

  @override
  String get productOutOfStock => 'Product is out of stock!';

  @override
  String get productAddedToCart => 'Product successfully added to cart!';

  @override
  String get goToCart => 'Go to Cart';

  @override
  String get showFirst => 'Show first';

  @override
  String get sortPopular => 'Popular';

  @override
  String get sortCheap => 'Cheap';

  @override
  String get sortExpensive => 'Expensive';

  @override
  String get myData => 'My Data';

  @override
  String get save => 'Save';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get fillAllFields => 'Please fill in all fields';

  @override
  String profileUpdateError(String message) {
    return 'Error updating profile: $message';
  }

  @override
  String error(String message) {
    return 'Error: $message';
  }

  @override
  String get faqTicketAfterPayment => 'How is the ticket issued after payment?';

  @override
  String get faqTicketAfterPaymentAnswer => 'The ticket is issued automatically after payment. You can see it in the My Profile section.';

  @override
  String get faqDeliveryMethod => 'How is delivery carried out?';

  @override
  String get faqDeliveryMethodAnswer => 'Delivery is carried out through KazPost. You will receive a notification when your order is shipped.';

  @override
  String get faqDeliveryTime => 'How long does delivery take?';

  @override
  String get faqDeliveryTimeAnswer => 'Delivery usually takes 3 to 7 business days, depending on your region.';

  @override
  String get faqCancelOrder => 'Can I cancel my order after payment?';

  @override
  String get faqCancelOrderAnswer => 'Yes, you can cancel your order before it is shipped. To do this, contact our support team.';

  @override
  String get faqTrackOrder => 'How can I track my order?';

  @override
  String get faqTrackOrderAnswer => 'After shipping, you will receive a tracking number. You can track your package on the KazPost website or in the My Orders section.';

  @override
  String get errorTitle => 'Error';

  @override
  String get success => 'Success!';

  @override
  String get orderDetails => 'Order Details';

  @override
  String get noData => 'No data';

  @override
  String get recipient => 'Recipient:';

  @override
  String get noName => 'No name';

  @override
  String get noPhone => 'No phone number';

  @override
  String get deliveryDate => 'Delivery Date:';

  @override
  String orderId(String id) {
    return 'Order ID: $id';
  }

  @override
  String get orderStatusPaymentPending => 'Pending Payment';

  @override
  String get orderStatusProcessing => 'Processing';

  @override
  String get orderStatusWay => 'On the Way';

  @override
  String get orderStatusPickup => 'Waiting at branch';

  @override
  String get orderStatusDelivered => 'Delivered';

  @override
  String get orderStatusCanceled => 'Canceled';

  @override
  String get orderStatusAssembling => 'Assembling';

  @override
  String get orderStatusAbandoned => 'Abandoned';

  @override
  String get orderStatusPaymentFailed => 'Payment Failed';

  @override
  String get orderProcessingMessage => 'Your items are reserved, order is being processed. You will receive a notification when the order is sent for assembly';

  @override
  String get ticketsWillBeAwarded => 'Tickets will be awarded';

  @override
  String get totalAmount => 'Total Amount';

  @override
  String get items => 'Items';

  @override
  String get discount => 'Discount';

  @override
  String get promotionalNumbers => 'Promotional Numbers';

  @override
  String get delivery => 'Delivery';

  @override
  String get free => 'Free';

  @override
  String get total => 'Total';

  @override
  String get paid => 'Paid';

  @override
  String get unpaid => 'Unpaid';

  @override
  String get enterPhoneNumber => 'Enter your\nphone number';

  @override
  String get weWillSendSms => 'We will send an SMS with a verification code';

  @override
  String get getCode => 'Get Code';

  @override
  String get orderConsentText => 'By tapping the button, you agree to the Offer terms and the Privacy policy';

  @override
  String get orderConsentOffer => 'Offer terms';

  @override
  String get orderConsentPrivacy => 'Privacy policy';

  @override
  String get termsAndPrivacy => 'By clicking the \"Get Code\" button, you accept the terms of use and privacy policy';

  @override
  String get userAgreement => 'terms of use';

  @override
  String get privacyPolicy => 'privacy policy';

  @override
  String get greeting => 'Hello!';

  @override
  String get cannotLogin => 'Can\'t log in?';

  @override
  String get createPinTitle => 'Create a PIN';

  @override
  String get confirmPinTitle => 'Repeat the PIN';

  @override
  String get pinMismatch => 'PINs don\'t match';

  @override
  String get wrongPin => 'Wrong PIN code';

  @override
  String get fillInData => 'Fill in your details';

  @override
  String get selectCity => 'Select city';

  @override
  String get enterCode => 'Enter Code';

  @override
  String sentToNumber(String phoneNumber) {
    return 'We sent it to the number\n+7 $phoneNumber';
  }

  @override
  String get signIn => 'Sign In';

  @override
  String get market => 'Market';

  @override
  String get streams => 'Streams';

  @override
  String get orders => 'Orders';

  @override
  String get searchHomeHint => 'What were you looking for?';

  @override
  String get all => 'All';

  @override
  String get plusPrice => 'With Plus';

  @override
  String sellerOrders(String count) {
    return '$count orders';
  }

  @override
  String get reviews => 'Reviews';

  @override
  String reviewsCount(String count) {
    return '$count reviews';
  }

  @override
  String get readAll => 'Read all';

  @override
  String get relatedProducts => 'You might also like';

  @override
  String get buy => 'Buy';

  @override
  String get newTag => 'New';

  @override
  String get hitTag => 'Hit';

  @override
  String get myTickets => 'My tickets';

  @override
  String get specifyDeliveryAddress => 'Specify delivery address';

  @override
  String get myOrders => 'My orders';

  @override
  String get orderStatus => 'Order status';

  @override
  String get myCard => 'My card';

  @override
  String get contacts => 'Contacts';

  @override
  String get sattyJuldyz => 'Satty juldyz';

  @override
  String get techSupport => 'Tech support';

  @override
  String get inviteFriends => 'Invite friends';

  @override
  String get goToPayment => 'Go to payment';

  @override
  String get clearCart => 'Clear';

  @override
  String get youSaved => 'You saved';

  @override
  String get recommended => 'Recommended';

  @override
  String get notAvailable => 'Not available';

  @override
  String get defaultDescription => 'A high-quality product that meets your daily care needs. Carefully selected ingredients ensure effective results. Suitable for all skin types. Recommended by professionals.';

  @override
  String get liveNow => 'Live now';

  @override
  String get otpSubtitle => 'We sent a 4-digit code\nto your phone';

  @override
  String get resendCode => 'Resend code';

  @override
  String get confirm => 'Confirm';

  @override
  String get continueAction => 'Continue';

  @override
  String get notificationCategoryPurchase => 'Purchase';

  @override
  String get notificationCategoryDelivery => 'Delivery';

  @override
  String get notificationCategoryStream => 'Streams';

  @override
  String get notificationCategorySubscription => 'Subscription';

  @override
  String get noNotifications => 'No notifications';

  @override
  String get selectAddress => 'Select address';

  @override
  String get noSavedAddresses => 'You don\'t have any saved addresses yet';

  @override
  String get deliveryAddressesTitle => 'Delivery addresses';

  @override
  String get deliveryAddressTitle => 'Delivery address';

  @override
  String get addMoreAddress => 'Add another address';

  @override
  String get saveAddress => 'Save address';

  @override
  String get newAddress => 'New address';

  @override
  String addressLabeled(String label) {
    return '“$label” address';
  }

  @override
  String get addressAdded => 'Address added';

  @override
  String get addressDeleted => 'Address deleted';

  @override
  String get deleteAddressTitle => 'Delete address?';

  @override
  String get deleteAddressMessage => 'Are you sure you want to delete this address?';

  @override
  String get deleteAction => 'Delete';

  @override
  String get addAction => 'Add';

  @override
  String get savingInProgress => 'Saving...';

  @override
  String get addressNameLabel => 'Address name';

  @override
  String get addressNameHint => 'For example: Home or work';

  @override
  String get enterAddressName => 'Enter a name';

  @override
  String get streetAndHouseHint => 'Street and house number';

  @override
  String get enterAddressLine => 'Enter the address';

  @override
  String get apartmentLabel => 'Apartment';

  @override
  String get entranceLabel => 'Entrance';

  @override
  String get floorLabel => 'Floor';

  @override
  String get postalIndexHint => 'Index';

  @override
  String get enterPostalIndex => 'Enter the index';

  @override
  String get selectCityFirst => 'Select a city';

  @override
  String get selectRegion => 'Select a region';

  @override
  String get addressesLoadError => 'Failed to load addresses';

  @override
  String get addressAddError => 'Failed to add the address';

  @override
  String get addressSaveError => 'Failed to save the address';

  @override
  String get addressDeleteError => 'Failed to delete the address';

  @override
  String get addAddress => 'Add address';

  @override
  String get raffleTab => 'Raffles';

  @override
  String get allShopsTab => 'All shops';

  @override
  String get wholeCatalogTab => 'Whole catalog';

  @override
  String get catalogTileLottery => 'Raffle\nproducts';

  @override
  String get catalogTileDiscount => 'Discounted\nproducts';

  @override
  String get catalogTileMakeup => 'Makeup';

  @override
  String get catalogTilePerfume => 'Perfumery';

  @override
  String get catalogTileBodyCare => 'Body\ncare';

  @override
  String get catalogTileHairCare => 'Hair\ncare';

  @override
  String get catalogTileCosmeticSets => 'Cosmetic\nsets';

  @override
  String get catalogTileFaceCare => 'Face\ncare';

  @override
  String get catalogTileSunCare => 'Sun\ncare';

  @override
  String get catalogTileHygiene => 'Personal\nhygiene';

  @override
  String get catalogTileOralCare => 'Oral\ncare';

  @override
  String get raffleDefaultTitle => 'Raffle';

  @override
  String raffleDateLabel(String date) {
    return 'Date: $date';
  }

  @override
  String get raffleDateTbd => 'Date: TBD';

  @override
  String raffleGiftsCount(int count) {
    return '$count gifts';
  }

  @override
  String get raffleGiftsAction => 'View gifts';

  @override
  String get raffleGiftsTitle => 'Raffle gifts';

  @override
  String get raffleGiftsEmpty => 'No gifts yet';

  @override
  String get raffleEmpty => 'No active raffles yet';

  @override
  String get raffleLoadError => 'Failed to load raffle';

  @override
  String get raffleProductsEmpty => 'No products in this raffle yet';

  @override
  String get sortDiscount => 'Biggest discount';

  @override
  String get baseAvatar => 'Base';

  @override
  String get selectAvatar => 'Select';

  @override
  String get dateOfBirth => 'Date of birth';

  @override
  String get birthDateHint => 'dd-mm-yyyy';

  @override
  String get phoneNumberHint => '(000) - 00 - 00';

  @override
  String get addPhoto => 'Add photo';

  @override
  String get gallery => 'Gallery';

  @override
  String get camera => 'Camera';

  @override
  String shareAppMessage(String link) {
    return 'Hi! I\'m using this awesome app. Join me: $link';
  }

  @override
  String get shareAppError => 'Couldn\'t open the share sheet';

  @override
  String get ordersTabAll => 'All';

  @override
  String get ordersTabActive => 'Active';

  @override
  String get ordersTabCompleted => 'Completed';

  @override
  String get ordersTabReturn => 'Returns';

  @override
  String get ordersEmptyTitle => 'No orders';

  @override
  String get ordersEmptyMessage => 'Your orders will appear here';

  @override
  String get orderTagActive => 'Active';

  @override
  String get orderTagCompleted => 'Completed';

  @override
  String get orderTagReturn => 'Return';

  @override
  String get orderLeaveReview => 'Leave a review';

  @override
  String get orderInTransitMessage => 'Your order has been handed over for shipping. A little patience, your item is on its way.';

  @override
  String get orderDeliveredMessage => 'Congratulations! The courier delivered your order. We\'d appreciate it if you rated our work.';

  @override
  String get orderReturnMessage => 'The order was returned or canceled.';

  @override
  String priceTenge(String price) {
    return '$price₸';
  }

  @override
  String get favoritesEmptyTitle => 'Nothing here yet';

  @override
  String get favoritesEmptySubtitle => 'Add items to favorites so you can easily come back to them later!';

  @override
  String get goShopping => 'Go shopping';

  @override
  String get myCards => 'My cards';

  @override
  String get paymentCard => 'Payment card';

  @override
  String get addCard => 'Add card';

  @override
  String get cardsEmptyTitle => 'No cards';

  @override
  String get cardsEmptySubtitle => 'You don\'t have any saved cards yet';

  @override
  String get contactsTitle => 'Contacts';

  @override
  String get callCenter => 'Call center';

  @override
  String get callCenterSubtitle => 'We\'ll consult and help\nyou place an order';

  @override
  String get acceptCallsHours => 'We accept calls from 10:00 to 20:00';

  @override
  String get respondHours => 'We reply from 10:00 to 20:00';

  @override
  String get writeOnWhatsapp => 'Message on Whatsapp';

  @override
  String get writeOnTelegram => 'Message on Telegram';

  @override
  String get deliverySectionTitle => 'Delivery';

  @override
  String get deliverySectionSubtitle => 'Updates are posted in our Telegram channel';

  @override
  String get selfPickupSectionTitle => 'Self-pickup address';

  @override
  String get branches => 'Branches';

  @override
  String get loginRequired => 'Sign in';

  @override
  String get loginRequiredHint => 'Sign in to your account to continue';

  @override
  String get addToCartFailed => 'Couldn\'t add to cart';

  @override
  String get pullToRefresh => 'Pull down to refresh';

  @override
  String get refreshing => 'Refreshing…';

  @override
  String get removeFromCartFailed => 'Couldn\'t remove from cart';

  @override
  String get paymentAmountTitle => 'Payment amount:';

  @override
  String get paymentSumLabel => 'Amount:';

  @override
  String get paymentCommissionLabel => 'Commission:';

  @override
  String get paymentTermsPart1 => 'By proceeding with the payment, you automatically';

  @override
  String get paymentTermsLinkText => 'agree';

  @override
  String get paymentTermsPart2 => 'to the terms';

  @override
  String get payButton => 'Pay';

  @override
  String get fromTitle => 'From';

  @override
  String get fromOtherCard => 'From another card';

  @override
  String get removeCardTitle => 'Remove card?';

  @override
  String get removeCardSubtitle => 'Are you sure you want to remove this card';

  @override
  String get removeAction => 'Remove';

  @override
  String get enterCardDataTitle => 'Enter card details';

  @override
  String get cardExpiryLabel => 'Expiry date';

  @override
  String get cardExpiryHint => 'MM/YY';

  @override
  String get cardCvvLabel => 'CVV code';

  @override
  String get saveCardData => 'Save card details';

  @override
  String get cardWarning => 'Make sure the card allows online transactions and has sufficient limit';

  @override
  String get orderAcceptedTitle => 'Your order is accepted!';

  @override
  String orderIdLabel(String id) {
    return 'Order ID: $id';
  }

  @override
  String get receiptItemsLabel => 'Items:';

  @override
  String get receiptSavedLabel => 'Saved:';

  @override
  String get receiptTicketsLabel => 'Tickets:';

  @override
  String get receiptPaymentMethodLabel => 'Payment method:';

  @override
  String get viewOrderStatus => 'View status';

  @override
  String get viewersLabel => 'Viewers';

  @override
  String get streamInactiveTitle => 'Stream is currently inactive';

  @override
  String get streamInactiveSubtitle => 'Wait for the broadcast to start';

  @override
  String get searchHint => 'Search products…';

  @override
  String get searchPrompt => 'Start typing to find a product';

  @override
  String get searchEmpty => 'Nothing found';

  @override
  String get searchError => 'Search failed. Please try again';

  @override
  String get onAirNow => 'On air now';

  @override
  String get giftButton => 'Gift';

  @override
  String get commentInputHint => 'Type a comment...';

  @override
  String get inCart => 'In Cart';

  @override
  String get kaspiPayTitle => 'Kaspi payment';

  @override
  String kaspiAmountToPay(String amount) {
    return 'To pay: $amount';
  }

  @override
  String get kaspiScanOrPay => 'Scan the QR code or tap «Pay» to open Kaspi';

  @override
  String get kaspiWaitingPayment => 'Waiting for payment…';

  @override
  String get kaspiPaymentFailed => 'Payment failed';

  @override
  String get kaspiLinkExpired => 'The payment link has expired';

  @override
  String get kaspiPayAgain => 'Pay again';

  @override
  String sellerRaffleDate(String date) {
    return 'Raffle: $date';
  }

  @override
  String get sellersEmpty => 'No shops yet';

  @override
  String get sellersLoadError => 'Failed to load shops';

  @override
  String get sellerProductsEmpty => 'This shop has no products yet';

  @override
  String get sellerNotFound => 'This shop is no longer available';

  @override
  String get sellerStoreTitleFallback => 'Shop';

  @override
  String ticketsBadge(String count) {
    return '+$count';
  }

  @override
  String get productUnavailable => 'This product is no longer available';

  @override
  String get plusPriceActive => 'Your Plus price';

  @override
  String get reviewsEmpty => 'No reviews yet';

  @override
  String get reviewAnonymous => 'Buyer';

  @override
  String get reviewComposerHint => 'Share your impressions of the product';

  @override
  String get reviewSend => 'Send';

  @override
  String get reviewSubmitted => 'Thanks for your review!';

  @override
  String get reviewAlreadyLeft => 'You have already reviewed this product';

  @override
  String get reviewTooManyRequests => 'Too many attempts. Try again in a minute';

  @override
  String get reviewSubmitError => 'Couldn\'t send the review';

  @override
  String get reviewsLoadError => 'Failed to load reviews';

  @override
  String shareProductMessage(String name, String price) {
    return '$name — $price. Found it in Bai Market.';
  }

  @override
  String shareProductMessageNoPrice(String name) {
    return '$name. Found it in Bai Market.';
  }

  @override
  String cartItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '$count item',
    );
    return '$_temp0';
  }

  @override
  String get checkoutShort => 'Checkout';

  @override
  String get cartClearFailed => 'Couldn\'t clear the cart';

  @override
  String get cartNotEnoughStock => 'Not enough items in stock';

  @override
  String get cartQuantityChangeFailed => 'Couldn\'t change the quantity — the item was removed, please add it again';

  @override
  String cartItemRemovedByStock(String name) {
    return '«$name» is out of stock and was removed';
  }

  @override
  String cartItemPriceChanged(String name) {
    return '«$name» price has changed';
  }

  @override
  String cartItemQuantityReduced(String name, String quantity) {
    return '«$name» quantity reduced to $quantity';
  }

  @override
  String get cartRefreshFailed => 'Couldn\'t refresh the cart';

  @override
  String get pushPermissionTitle => 'Turn on notifications';

  @override
  String get pushPermissionBody => 'We\'ll let you know about order status, raffle results and new arrivals';

  @override
  String get pushPermissionAllow => 'Turn on';

  @override
  String get pushPermissionLater => 'Later';

  @override
  String get pushDisabledBanner => 'Notifications are turned off';

  @override
  String get pushEnableAction => 'Turn on';

  @override
  String get notificationsSettingsTitle => 'Notifications';

  @override
  String get notificationsOn => 'On';

  @override
  String get notificationsOff => 'Off';

  @override
  String get notificationsLoadError => 'Failed to load notifications';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get addedToCart => 'Added to cart';

  @override
  String get outOfStock => 'Out of stock';

  @override
  String get pullToRefreshHint => 'Pull down to refresh';

  @override
  String get streamsLoadError => 'Couldn\'t load streams';

  @override
  String get streamsEmptyTitle => 'No streams right now';

  @override
  String get streamsEmptySubtitle => 'Come back a bit later';

  @override
  String get streamErrorGeneric => 'Something went wrong';

  @override
  String get streamEndedTitle => 'The stream has ended';

  @override
  String get streamEndedSubtitle => 'Pick another broadcast';

  @override
  String get streamReconnecting => 'Reconnecting…';

  @override
  String get streamConnectionLost => 'Connection lost';

  @override
  String get streamRetry => 'Try again';

  @override
  String get streamChatTooLong => 'The message is too long';

  @override
  String get streamChatRateLimited => 'Too many messages, slow down';

  @override
  String get streamProductsTitle => 'Products in the stream';

  @override
  String get streamGiftsTitle => 'Gifts';

  @override
  String get pinnedProductBadge => 'On air';

  @override
  String get streamHostCameraPaused => 'The host paused the camera';

  @override
  String get streamStartCta => 'Go live';

  @override
  String get streamResumeCta => 'Back to your stream';

  @override
  String get startStreamSheetTitle => 'New stream';

  @override
  String get startStreamTitleLabel => 'Stream title';

  @override
  String get startStreamTitleHint => 'For example: Sneaker sale';

  @override
  String get startStreamTitleTooShort => 'Add a longer title';

  @override
  String get startStreamSubmit => 'Start';

  @override
  String get startStreamFailed => 'Couldn\'t start the stream';

  @override
  String get streamAccessDenied => 'Streams are unavailable, please contact support';

  @override
  String get streamAlreadyLiveTitle => 'You already have a live stream';

  @override
  String get streamAlreadyLiveMessage => 'You can only run one stream at a time. End the current one or open it as a viewer.';

  @override
  String get streamEndAndRestart => 'End and restart';

  @override
  String get streamOpenAsViewer => 'Open as viewer';

  @override
  String get streamStopConfirmTitle => 'End the stream?';

  @override
  String get streamStopConfirmAction => 'End';

  @override
  String get hostCameraPaused => 'Camera is off';

  @override
  String get hostPickProductTitle => 'Show a product';

  @override
  String get hostPinProduct => 'Show';

  @override
  String get hostUnpinProduct => 'Hide the product';

  @override
  String get hostNoProducts => 'No products yet';

  @override
  String get hostPermissionDeniedTitle => 'Camera and microphone are required';

  @override
  String get hostPermissionDeniedMessage => 'Allow access in settings to go live.';

  @override
  String get hostOpenSettings => 'Settings';

  @override
  String get storyOpenProduct => 'View product';

  @override
  String stockLeft(int count) {
    return '$count left!';
  }

  @override
  String get updateForcedTitle => 'Update required';

  @override
  String get updateForcedMessage => 'This version of Bai Market is no longer supported. Install the latest one to keep shopping — it only takes a moment.';

  @override
  String get updateRecommendedTitle => 'A new version is out';

  @override
  String get updateRecommendedMessage => 'We have added new features and ironed out a few things. Updating takes less than a minute.';

  @override
  String get updateNow => 'Update';

  @override
  String get updateLater => 'Later';

  @override
  String get updateWhatsNew => 'What\'s new';

  @override
  String profileVersion(String version) {
    return 'Version: $version';
  }

  @override
  String updateVersionBadge(String version) {
    return 'Version $version';
  }

  @override
  String get updateStoreOpenFailed => 'Couldn\'t open the app store. Please try again.';

  @override
  String get checkoutTitle => 'Checkout';

  @override
  String get savedAddressTitle => 'Saved address';

  @override
  String get selectSavedAddressFirst => 'Choose a saved address';

  @override
  String get chooseAction => 'choose';

  @override
  String get changeAction => 'Change';

  @override
  String get addressFallbackTitle => 'Address';

  @override
  String branchWithAddress(String address) {
    return 'Branch: $address';
  }

  @override
  String get cityFallbackName => 'City';

  @override
  String get recipientNameCourierLabel => 'Who will meet the courier (full name)';

  @override
  String get recipientNamePickupLabel => 'Who will pick up the order (full name)';

  @override
  String get recipientNameHint => 'For example: Asylbek Daniyal';

  @override
  String get processingAction => 'Processing…';

  @override
  String get kaspiPaymentStartFailed => 'Could not start the Kaspi payment';

  @override
  String get paymentMethodsTitle => 'Payment methods';

  @override
  String get deliveryByCourier => 'By courier';

  @override
  String get deliverySelfPickup => 'Self-pickup';

  @override
  String get filialDistrict => 'Bostandyk district';

  @override
  String get filialAddressLine => '112 Abdully Rozybakieva street';

  @override
  String get deliveryMethodBranch => 'To a Kazpost branch';

  @override
  String get deliveryMethodBranchHint => 'You will pick it up at the post office with the tracking number';

  @override
  String get deliveryMethodDoor => 'To the door';

  @override
  String get deliveryMethodDoorHint => 'A Go Post courier will bring it home';

  @override
  String get houseNumberLabel => 'House and apartment';

  @override
  String get houseNumberHint => '150, apt. 25';

  @override
  String get enterHouseNumber => 'Enter the house and apartment';

  @override
  String get postalCodeInvalidLength => 'The postal code must be 6 digits';

  @override
  String get enterPostalForDelivery => 'Enter the postal code to see the delivery price';

  @override
  String get selectAddressForDelivery => 'Choose an address to see the delivery price';

  @override
  String get deliveryPriceCalculating => 'Calculating…';

  @override
  String get amountToPay => 'To pay';

  @override
  String get trackingNumberLabel => 'Tracking number';

  @override
  String get trackOnKazpost => 'Track on post.kz';

  @override
  String get trackingNumberCopied => 'Tracking number copied';

  @override
  String get orderStatusPickupKazpostMessage => 'The parcel is waiting at the Kazpost branch. Pick it up with the tracking number';

  @override
  String get deliveryQuoteFailed => 'Could not calculate the delivery. Please try again';
}
