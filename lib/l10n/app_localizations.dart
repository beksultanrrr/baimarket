import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_kk.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('kk'),
    Locale('ru')
  ];

  /// The name of the application
  ///
  /// In en, this message translates to:
  /// **'Bai Market'**
  String get appName;

  /// Welcome message
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// Login button text
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Register button text
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// Email field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Confirm password field label
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// Forgot password button text
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// Don't have an account text
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// Already have an account text
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// Phone field label
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// Name field label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Surname field label
  ///
  /// In en, this message translates to:
  /// **'Surname'**
  String get surname;

  /// Phone number field label
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// Name field hint
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterName;

  /// Surname field hint
  ///
  /// In en, this message translates to:
  /// **'Enter your surname'**
  String get enterSurname;

  /// Phone number field hint
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get enterPhone;

  /// Email field hint
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterEmail;

  /// Password field hint
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// Confirm password field hint
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get enterConfirmPassword;

  /// Cart menu item text
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cart;

  /// Favorites section title
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// Profile menu item text
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Settings section title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Language setting
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Notifications setting
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Logout button text
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Catalog menu item text
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get catalog;

  /// Free delivery text
  ///
  /// In en, this message translates to:
  /// **'Free delivery'**
  String get freeDelivery;

  /// Delivery address label
  ///
  /// In en, this message translates to:
  /// **'Delivery Address:'**
  String get deliveryAddress;

  /// Address field hint
  ///
  /// In en, this message translates to:
  /// **'Example: Auezova 34'**
  String get addressExample;

  /// Postal code field label
  ///
  /// In en, this message translates to:
  /// **'Postal Code'**
  String get postalCode;

  /// Card number field label
  ///
  /// In en, this message translates to:
  /// **'Card number'**
  String get cardNumber;

  /// Card number field hint
  ///
  /// In en, this message translates to:
  /// **'Enter card number'**
  String get enterCardNumber;

  /// CVV field label
  ///
  /// In en, this message translates to:
  /// **'CVV'**
  String get cvv;

  /// Name field label for delivery
  ///
  /// In en, this message translates to:
  /// **'Who will meet the courier?'**
  String get whoWillMeet;

  /// Name field hint for delivery
  ///
  /// In en, this message translates to:
  /// **'Example: Abzal'**
  String get nameExample;

  /// Try again button text
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// Empty city list message
  ///
  /// In en, this message translates to:
  /// **'City list is empty'**
  String get emptyCityList;

  /// Default product name
  ///
  /// In en, this message translates to:
  /// **'Product name'**
  String get productName;

  /// Default product description text
  ///
  /// In en, this message translates to:
  /// **'Product description'**
  String get productDescription;

  /// Home address label
  ///
  /// In en, this message translates to:
  /// **'Home Address'**
  String get homeAddress;

  /// Postal index text with placeholder
  ///
  /// In en, this message translates to:
  /// **'Postal index: {index}'**
  String postalIndex(String index);

  /// My addresses section title
  ///
  /// In en, this message translates to:
  /// **'My Addresses'**
  String get myAddresses;

  /// Order history page title
  ///
  /// In en, this message translates to:
  /// **'Order History'**
  String get orderHistory;

  /// Support section title
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// Support page title
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get supportTitle;

  /// Support working hours message
  ///
  /// In en, this message translates to:
  /// **'We are ready to help you\nevery day from 9:00 - 22:00'**
  String get supportWorkingHours;

  /// WhatsApp button text
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsapp;

  /// Telegram button text
  ///
  /// In en, this message translates to:
  /// **'Telegram'**
  String get telegram;

  /// FAQ section title
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get faq;

  /// Error message when URL cannot be opened
  ///
  /// In en, this message translates to:
  /// **'Failed to open {url}'**
  String failedToOpen(String url);

  /// Exit application button text
  ///
  /// In en, this message translates to:
  /// **'Exit Application'**
  String get exitApp;

  /// Exit application confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to exit the application?'**
  String get exitConfirmation;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Product out of stock label
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get notInStock;

  /// Prize won message
  ///
  /// In en, this message translates to:
  /// **'You won!'**
  String get youWon;

  /// Contact message after winning
  ///
  /// In en, this message translates to:
  /// **'We will contact you soon'**
  String get weWillContactYou;

  /// Postal index text with placeholder
  ///
  /// In en, this message translates to:
  /// **'Index: {index}'**
  String index(String index);

  /// Price with currency
  ///
  /// In en, this message translates to:
  /// **'{price} ₸'**
  String price(String price);

  /// Old price with currency
  ///
  /// In en, this message translates to:
  /// **'{price} ₸'**
  String oldPrice(String price);

  /// No description provided for @productDescriptionShort.
  ///
  /// In en, this message translates to:
  /// **'Provides ease and comfort in makeup all...'**
  String get productDescriptionShort;

  /// Home menu item text
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Products count text
  ///
  /// In en, this message translates to:
  /// **'products'**
  String get products;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @in_sale.
  ///
  /// In en, this message translates to:
  /// **'In Sale'**
  String get in_sale;

  /// No description provided for @not_in_sale.
  ///
  /// In en, this message translates to:
  /// **'Not in sale'**
  String get not_in_sale;

  /// No description provided for @purchases.
  ///
  /// In en, this message translates to:
  /// **'Purchases'**
  String get purchases;

  /// No description provided for @orderAgain.
  ///
  /// In en, this message translates to:
  /// **'Order again'**
  String get orderAgain;

  /// No description provided for @myPrizes.
  ///
  /// In en, this message translates to:
  /// **'My prizes'**
  String get myPrizes;

  /// No description provided for @noPrizes.
  ///
  /// In en, this message translates to:
  /// **'No prizes'**
  String get noPrizes;

  /// Empty cart message
  ///
  /// In en, this message translates to:
  /// **'Cart is empty'**
  String get cartEmpty;

  /// Empty cart hint message
  ///
  /// In en, this message translates to:
  /// **'Added items will appear here'**
  String get addedItemsWillAppearHere;

  /// Go to shopping button text
  ///
  /// In en, this message translates to:
  /// **'Go shopping'**
  String get goToShopping;

  /// Proceed to checkout button text
  ///
  /// In en, this message translates to:
  /// **'Proceed to checkout'**
  String get proceedToCheckout;

  /// Price per item text
  ///
  /// In en, this message translates to:
  /// **'{price} ₸/item'**
  String pricePerItem(String price);

  /// Maximum items reached message
  ///
  /// In en, this message translates to:
  /// **'Cannot add more. This is the maximum.'**
  String get cannotAddMore;

  /// No description provided for @prize_goods.
  ///
  /// In en, this message translates to:
  /// **'Prize goods'**
  String get prize_goods;

  /// No description provided for @number_of_tickets.
  ///
  /// In en, this message translates to:
  /// **'Number for participation'**
  String get number_of_tickets;

  /// No description provided for @tickets.
  ///
  /// In en, this message translates to:
  /// **'tickets'**
  String get tickets;

  /// Product description section title
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// Add to cart button text
  ///
  /// In en, this message translates to:
  /// **'Add to Cart'**
  String get addToCart;

  /// Product out of stock message
  ///
  /// In en, this message translates to:
  /// **'Product is out of stock!'**
  String get productOutOfStock;

  /// Product added to cart success message
  ///
  /// In en, this message translates to:
  /// **'Product successfully added to cart!'**
  String get productAddedToCart;

  /// Go to cart button text
  ///
  /// In en, this message translates to:
  /// **'Go to Cart'**
  String get goToCart;

  /// Sorting modal title
  ///
  /// In en, this message translates to:
  /// **'Show first'**
  String get showFirst;

  /// Sort by popularity option
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get sortPopular;

  /// Sort by price ascending option
  ///
  /// In en, this message translates to:
  /// **'Cheapest first'**
  String get sortCheap;

  /// Sort by price descending option
  ///
  /// In en, this message translates to:
  /// **'Most expensive first'**
  String get sortExpensive;

  /// My data page title
  ///
  /// In en, this message translates to:
  /// **'My Data'**
  String get myData;

  /// Save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Delete account button text
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// Validation message for empty fields
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields'**
  String get fillAllFields;

  /// Profile update error message
  ///
  /// In en, this message translates to:
  /// **'Error updating profile: {message}'**
  String profileUpdateError(String message);

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String error(String message);

  /// FAQ question about ticket issuance
  ///
  /// In en, this message translates to:
  /// **'How is the ticket issued after payment?'**
  String get faqTicketAfterPayment;

  /// FAQ answer about ticket issuance
  ///
  /// In en, this message translates to:
  /// **'The ticket is issued automatically after payment. You can see it in the My Profile section.'**
  String get faqTicketAfterPaymentAnswer;

  /// FAQ question about delivery method
  ///
  /// In en, this message translates to:
  /// **'How is delivery carried out?'**
  String get faqDeliveryMethod;

  /// FAQ answer about delivery method
  ///
  /// In en, this message translates to:
  /// **'Delivery is carried out through KazPost. You will receive a notification when your order is shipped.'**
  String get faqDeliveryMethodAnswer;

  /// FAQ question about delivery time
  ///
  /// In en, this message translates to:
  /// **'How long does delivery take?'**
  String get faqDeliveryTime;

  /// FAQ answer about delivery time
  ///
  /// In en, this message translates to:
  /// **'Delivery usually takes 3 to 7 business days, depending on your region.'**
  String get faqDeliveryTimeAnswer;

  /// FAQ question about order cancellation
  ///
  /// In en, this message translates to:
  /// **'Can I cancel my order after payment?'**
  String get faqCancelOrder;

  /// FAQ answer about order cancellation
  ///
  /// In en, this message translates to:
  /// **'Yes, you can cancel your order before it is shipped. To do this, contact our support team.'**
  String get faqCancelOrderAnswer;

  /// FAQ question about order tracking
  ///
  /// In en, this message translates to:
  /// **'How can I track my order?'**
  String get faqTrackOrder;

  /// FAQ answer about order tracking
  ///
  /// In en, this message translates to:
  /// **'After shipping, you will receive a tracking number. You can track your package on the KazPost website or in the My Orders section.'**
  String get faqTrackOrderAnswer;

  /// Error title for snackbar
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorTitle;

  /// Success title for snackbar
  ///
  /// In en, this message translates to:
  /// **'Success!'**
  String get success;

  /// Order details page title
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get orderDetails;

  /// No data available message
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// Recipient label
  ///
  /// In en, this message translates to:
  /// **'Recipient:'**
  String get recipient;

  /// No name available message
  ///
  /// In en, this message translates to:
  /// **'No name'**
  String get noName;

  /// No phone number available message
  ///
  /// In en, this message translates to:
  /// **'No phone number'**
  String get noPhone;

  /// Delivery date label
  ///
  /// In en, this message translates to:
  /// **'Delivery Date:'**
  String get deliveryDate;

  /// Order ID text with placeholder
  ///
  /// In en, this message translates to:
  /// **'Order ID: {id}'**
  String orderId(String id);

  /// Order status: Payment Pending
  ///
  /// In en, this message translates to:
  /// **'Pending Payment'**
  String get orderStatusPaymentPending;

  /// Order status: Processing
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get orderStatusProcessing;

  /// Order status: On the Way
  ///
  /// In en, this message translates to:
  /// **'On the Way'**
  String get orderStatusWay;

  /// Order status: Ready for Pickup
  ///
  /// In en, this message translates to:
  /// **'Ready for Pickup'**
  String get orderStatusPickup;

  /// Order status: Delivered
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get orderStatusDelivered;

  /// Order status: Canceled
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get orderStatusCanceled;

  /// Order status: Assembling
  ///
  /// In en, this message translates to:
  /// **'Assembling'**
  String get orderStatusAssembling;

  /// Order status: Abandoned
  ///
  /// In en, this message translates to:
  /// **'Abandoned'**
  String get orderStatusAbandoned;

  /// Order status: Payment Failed
  ///
  /// In en, this message translates to:
  /// **'Payment Failed'**
  String get orderStatusPaymentFailed;

  /// Order processing status message
  ///
  /// In en, this message translates to:
  /// **'Your items are reserved, order is being processed. You will receive a notification when the order is sent for assembly'**
  String get orderProcessingMessage;

  /// Tickets award message
  ///
  /// In en, this message translates to:
  /// **'Tickets will be awarded'**
  String get ticketsWillBeAwarded;

  /// Total amount label
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalAmount;

  /// Items label
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items;

  /// Discount label
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// Promotional numbers label
  ///
  /// In en, this message translates to:
  /// **'Promotional Numbers'**
  String get promotionalNumbers;

  /// Delivery label
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get delivery;

  /// Free delivery text
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// Total label
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// Paid status
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// Unpaid status
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get unpaid;

  /// Phone number input title
  ///
  /// In en, this message translates to:
  /// **'Enter your\nphone number'**
  String get enterPhoneNumber;

  /// SMS verification message
  ///
  /// In en, this message translates to:
  /// **'We will send an SMS with a verification code'**
  String get weWillSendSms;

  /// Get verification code button
  ///
  /// In en, this message translates to:
  /// **'Get Code'**
  String get getCode;

  /// Terms and privacy policy text
  ///
  /// In en, this message translates to:
  /// **'By clicking the \"Get Code\" button, you accept the terms of use and privacy policy'**
  String get termsAndPrivacy;

  /// Enter verification code title
  ///
  /// In en, this message translates to:
  /// **'Enter Code'**
  String get enterCode;

  /// SMS sent confirmation message
  ///
  /// In en, this message translates to:
  /// **'We sent it to the number\n+7 {phoneNumber}'**
  String sentToNumber(String phoneNumber);

  /// Sign in button text
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @market.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get market;

  /// No description provided for @streams.
  ///
  /// In en, this message translates to:
  /// **'Streams'**
  String get streams;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @searchHomeHint.
  ///
  /// In en, this message translates to:
  /// **'What were you looking for?'**
  String get searchHomeHint;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @plusPrice.
  ///
  /// In en, this message translates to:
  /// **'With Plus'**
  String get plusPrice;

  /// No description provided for @sellerOrders.
  ///
  /// In en, this message translates to:
  /// **'{count} orders'**
  String sellerOrders(String count);

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @reviewsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} reviews'**
  String reviewsCount(String count);

  /// No description provided for @readAll.
  ///
  /// In en, this message translates to:
  /// **'Read all'**
  String get readAll;

  /// No description provided for @relatedProducts.
  ///
  /// In en, this message translates to:
  /// **'You might also like'**
  String get relatedProducts;

  /// No description provided for @buy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get buy;

  /// No description provided for @newTag.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newTag;

  /// No description provided for @hitTag.
  ///
  /// In en, this message translates to:
  /// **'Hit'**
  String get hitTag;

  /// No description provided for @myTickets.
  ///
  /// In en, this message translates to:
  /// **'My tickets'**
  String get myTickets;

  /// No description provided for @specifyDeliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Specify delivery address'**
  String get specifyDeliveryAddress;

  /// No description provided for @myOrders.
  ///
  /// In en, this message translates to:
  /// **'My orders'**
  String get myOrders;

  /// No description provided for @orderStatus.
  ///
  /// In en, this message translates to:
  /// **'Order status'**
  String get orderStatus;

  /// No description provided for @myCard.
  ///
  /// In en, this message translates to:
  /// **'My card'**
  String get myCard;

  /// No description provided for @contacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contacts;

  /// No description provided for @inviteFriends.
  ///
  /// In en, this message translates to:
  /// **'Invite friends'**
  String get inviteFriends;

  /// No description provided for @goToPayment.
  ///
  /// In en, this message translates to:
  /// **'Go to payment'**
  String get goToPayment;

  /// No description provided for @clearCart.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearCart;

  /// No description provided for @youSaved.
  ///
  /// In en, this message translates to:
  /// **'You saved'**
  String get youSaved;

  /// No description provided for @recommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get recommended;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get notAvailable;

  /// No description provided for @defaultDescription.
  ///
  /// In en, this message translates to:
  /// **'A high-quality product that meets your daily care needs. Carefully selected ingredients ensure effective results. Suitable for all skin types. Recommended by professionals.'**
  String get defaultDescription;

  /// No description provided for @liveNow.
  ///
  /// In en, this message translates to:
  /// **'Live now'**
  String get liveNow;

  /// No description provided for @otpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We sent a 4-digit code\nto your phone'**
  String get otpSubtitle;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @notificationCategoryPurchase.
  ///
  /// In en, this message translates to:
  /// **'Purchase'**
  String get notificationCategoryPurchase;

  /// No description provided for @notificationCategoryDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get notificationCategoryDelivery;

  /// No description provided for @notificationCategoryStream.
  ///
  /// In en, this message translates to:
  /// **'Streams'**
  String get notificationCategoryStream;

  /// No description provided for @notificationCategorySubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get notificationCategorySubscription;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @selectAddress.
  ///
  /// In en, this message translates to:
  /// **'Select address'**
  String get selectAddress;

  /// No description provided for @noSavedAddresses.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any saved addresses yet'**
  String get noSavedAddresses;

  /// No description provided for @addAddress.
  ///
  /// In en, this message translates to:
  /// **'Add address'**
  String get addAddress;

  /// Catalog tab label for raffles
  ///
  /// In en, this message translates to:
  /// **'Raffles'**
  String get raffleTab;

  /// Catalog top switcher label for shops view
  ///
  /// In en, this message translates to:
  /// **'All shops'**
  String get allShopsTab;

  /// Catalog top switcher label for catalog view
  ///
  /// In en, this message translates to:
  /// **'Whole catalog'**
  String get wholeCatalogTab;

  /// Fallback title when a raffle has no seller
  ///
  /// In en, this message translates to:
  /// **'Raffle'**
  String get raffleDefaultTitle;

  /// Raffle draw date label
  ///
  /// In en, this message translates to:
  /// **'Date: {date}'**
  String raffleDateLabel(String date);

  /// Raffle date placeholder when unknown
  ///
  /// In en, this message translates to:
  /// **'Date: TBD'**
  String get raffleDateTbd;

  /// Number of gifts in a raffle
  ///
  /// In en, this message translates to:
  /// **'{count} gifts'**
  String raffleGiftsCount(int count);

  /// Header button that opens the gifts sheet
  ///
  /// In en, this message translates to:
  /// **'View gifts'**
  String get raffleGiftsAction;

  /// Title of the gifts bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Raffle gifts'**
  String get raffleGiftsTitle;

  /// Empty state for raffle gifts sheet
  ///
  /// In en, this message translates to:
  /// **'No gifts yet'**
  String get raffleGiftsEmpty;

  /// Empty state for raffles list
  ///
  /// In en, this message translates to:
  /// **'No active raffles yet'**
  String get raffleEmpty;

  /// Raffle load error
  ///
  /// In en, this message translates to:
  /// **'Failed to load raffle'**
  String get raffleLoadError;

  /// Empty state for raffle products grid
  ///
  /// In en, this message translates to:
  /// **'No products in this raffle yet'**
  String get raffleProductsEmpty;

  /// Sort by discount option
  ///
  /// In en, this message translates to:
  /// **'Biggest discount'**
  String get sortDiscount;

  /// Label for the base avatar option (initial letter)
  ///
  /// In en, this message translates to:
  /// **'Base'**
  String get baseAvatar;

  /// Label for the custom photo avatar option
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get selectAvatar;

  /// Date of birth field label
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get dateOfBirth;

  /// Date of birth placeholder
  ///
  /// In en, this message translates to:
  /// **'dd-mm-yyyy'**
  String get birthDateHint;

  /// Phone number field placeholder
  ///
  /// In en, this message translates to:
  /// **'(000) - 00 - 00'**
  String get phoneNumberHint;

  /// Add photo bottom sheet title
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get addPhoto;

  /// Gallery option in the photo picker sheet
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// Camera option in the photo picker sheet
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// Message pre-filled in the system share sheet when inviting friends
  ///
  /// In en, this message translates to:
  /// **'Hi! I\'m using this awesome app. Join me: {link}'**
  String shareAppMessage(String link);

  /// Error shown when the native share sheet fails to open
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the share sheet'**
  String get shareAppError;

  /// No description provided for @ordersTabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get ordersTabAll;

  /// No description provided for @ordersTabActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get ordersTabActive;

  /// No description provided for @ordersTabCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get ordersTabCompleted;

  /// No description provided for @ordersTabReturn.
  ///
  /// In en, this message translates to:
  /// **'Returns'**
  String get ordersTabReturn;

  /// No description provided for @ordersEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No orders'**
  String get ordersEmptyTitle;

  /// No description provided for @ordersEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Your orders will appear here'**
  String get ordersEmptyMessage;

  /// No description provided for @orderTagActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get orderTagActive;

  /// No description provided for @orderTagCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get orderTagCompleted;

  /// No description provided for @orderTagReturn.
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get orderTagReturn;

  /// No description provided for @orderLeaveReview.
  ///
  /// In en, this message translates to:
  /// **'Leave a review'**
  String get orderLeaveReview;

  /// No description provided for @orderInTransitMessage.
  ///
  /// In en, this message translates to:
  /// **'Your order has been handed over for shipping. A little patience, your item is on its way.'**
  String get orderInTransitMessage;

  /// No description provided for @orderDeliveredMessage.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! The courier delivered your order. We\'d appreciate it if you rated our work.'**
  String get orderDeliveredMessage;

  /// No description provided for @orderReturnMessage.
  ///
  /// In en, this message translates to:
  /// **'The order was returned or canceled.'**
  String get orderReturnMessage;

  /// Price with tenge symbol (no space)
  ///
  /// In en, this message translates to:
  /// **'{price}₸'**
  String priceTenge(String price);

  /// No description provided for @favoritesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get favoritesEmptyTitle;

  /// No description provided for @favoritesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add items to favorites so you can easily come back to them later!'**
  String get favoritesEmptySubtitle;

  /// No description provided for @goShopping.
  ///
  /// In en, this message translates to:
  /// **'Go shopping'**
  String get goShopping;

  /// No description provided for @myCards.
  ///
  /// In en, this message translates to:
  /// **'My cards'**
  String get myCards;

  /// No description provided for @paymentCard.
  ///
  /// In en, this message translates to:
  /// **'Payment card'**
  String get paymentCard;

  /// No description provided for @addCard.
  ///
  /// In en, this message translates to:
  /// **'Add card'**
  String get addCard;

  /// No description provided for @cardsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No cards'**
  String get cardsEmptyTitle;

  /// No description provided for @cardsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any saved cards yet'**
  String get cardsEmptySubtitle;

  /// No description provided for @contactsTitle.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contactsTitle;

  /// No description provided for @callCenter.
  ///
  /// In en, this message translates to:
  /// **'Call center'**
  String get callCenter;

  /// No description provided for @callCenterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll consult and help\nyou place an order'**
  String get callCenterSubtitle;

  /// No description provided for @acceptCallsHours.
  ///
  /// In en, this message translates to:
  /// **'We accept calls from 10:00 to 20:00'**
  String get acceptCallsHours;

  /// No description provided for @respondHours.
  ///
  /// In en, this message translates to:
  /// **'We reply from 10:00 to 20:00'**
  String get respondHours;

  /// No description provided for @writeOnWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Message on Whatsapp'**
  String get writeOnWhatsapp;

  /// No description provided for @writeOnTelegram.
  ///
  /// In en, this message translates to:
  /// **'Message on Telegram'**
  String get writeOnTelegram;

  /// No description provided for @deliverySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get deliverySectionTitle;

  /// No description provided for @deliverySectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Updates are posted in our Telegram channel'**
  String get deliverySectionSubtitle;

  /// No description provided for @selfPickupSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Self-pickup address'**
  String get selfPickupSectionTitle;

  /// No description provided for @branches.
  ///
  /// In en, this message translates to:
  /// **'Branches'**
  String get branches;

  /// No description provided for @loginRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginRequired;

  /// No description provided for @loginRequiredHint.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account to continue'**
  String get loginRequiredHint;

  /// No description provided for @addToCartFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t add to cart'**
  String get addToCartFailed;

  /// No description provided for @pullToRefresh.
  ///
  /// In en, this message translates to:
  /// **'Pull down to refresh'**
  String get pullToRefresh;

  /// No description provided for @refreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing…'**
  String get refreshing;

  /// No description provided for @removeFromCartFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t remove from cart'**
  String get removeFromCartFailed;

  /// No description provided for @paymentAmountTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment amount:'**
  String get paymentAmountTitle;

  /// No description provided for @paymentSumLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount:'**
  String get paymentSumLabel;

  /// No description provided for @paymentCommissionLabel.
  ///
  /// In en, this message translates to:
  /// **'Commission:'**
  String get paymentCommissionLabel;

  /// No description provided for @paymentTermsPart1.
  ///
  /// In en, this message translates to:
  /// **'By proceeding with the payment, you automatically'**
  String get paymentTermsPart1;

  /// No description provided for @paymentTermsLinkText.
  ///
  /// In en, this message translates to:
  /// **'agree'**
  String get paymentTermsLinkText;

  /// No description provided for @paymentTermsPart2.
  ///
  /// In en, this message translates to:
  /// **'to the terms'**
  String get paymentTermsPart2;

  /// No description provided for @payButton.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get payButton;

  /// No description provided for @fromTitle.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get fromTitle;

  /// No description provided for @fromOtherCard.
  ///
  /// In en, this message translates to:
  /// **'From another card'**
  String get fromOtherCard;

  /// No description provided for @removeCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove card?'**
  String get removeCardTitle;

  /// No description provided for @removeCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this card'**
  String get removeCardSubtitle;

  /// No description provided for @removeAction.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeAction;

  /// No description provided for @enterCardDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter card details'**
  String get enterCardDataTitle;

  /// No description provided for @cardExpiryLabel.
  ///
  /// In en, this message translates to:
  /// **'Expiry date'**
  String get cardExpiryLabel;

  /// No description provided for @cardExpiryHint.
  ///
  /// In en, this message translates to:
  /// **'MM/YY'**
  String get cardExpiryHint;

  /// No description provided for @cardCvvLabel.
  ///
  /// In en, this message translates to:
  /// **'CVV code'**
  String get cardCvvLabel;

  /// No description provided for @saveCardData.
  ///
  /// In en, this message translates to:
  /// **'Save card details'**
  String get saveCardData;

  /// No description provided for @cardWarning.
  ///
  /// In en, this message translates to:
  /// **'Make sure the card allows online transactions and has sufficient limit'**
  String get cardWarning;

  /// No description provided for @orderAcceptedTitle.
  ///
  /// In en, this message translates to:
  /// **'Your order is accepted!'**
  String get orderAcceptedTitle;

  /// No description provided for @orderIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Order ID: {id}'**
  String orderIdLabel(String id);

  /// No description provided for @receiptItemsLabel.
  ///
  /// In en, this message translates to:
  /// **'Items:'**
  String get receiptItemsLabel;

  /// No description provided for @receiptSavedLabel.
  ///
  /// In en, this message translates to:
  /// **'Saved:'**
  String get receiptSavedLabel;

  /// No description provided for @receiptTicketsLabel.
  ///
  /// In en, this message translates to:
  /// **'Tickets:'**
  String get receiptTicketsLabel;

  /// No description provided for @receiptPaymentMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment method:'**
  String get receiptPaymentMethodLabel;

  /// No description provided for @viewOrderStatus.
  ///
  /// In en, this message translates to:
  /// **'View status'**
  String get viewOrderStatus;

  /// No description provided for @viewersLabel.
  ///
  /// In en, this message translates to:
  /// **'Viewers'**
  String get viewersLabel;

  /// No description provided for @streamInactiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Stream is currently inactive'**
  String get streamInactiveTitle;

  /// No description provided for @streamInactiveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Wait for the broadcast to start'**
  String get streamInactiveSubtitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search products…'**
  String get searchHint;

  /// No description provided for @searchPrompt.
  ///
  /// In en, this message translates to:
  /// **'Start typing to find a product'**
  String get searchPrompt;

  /// No description provided for @searchEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing found'**
  String get searchEmpty;

  /// No description provided for @searchError.
  ///
  /// In en, this message translates to:
  /// **'Search failed. Please try again'**
  String get searchError;

  /// No description provided for @onAirNow.
  ///
  /// In en, this message translates to:
  /// **'On air now'**
  String get onAirNow;

  /// No description provided for @giftButton.
  ///
  /// In en, this message translates to:
  /// **'Gift'**
  String get giftButton;

  /// No description provided for @commentInputHint.
  ///
  /// In en, this message translates to:
  /// **'Type a comment...'**
  String get commentInputHint;

  /// No description provided for @inCart.
  ///
  /// In en, this message translates to:
  /// **'In Cart'**
  String get inCart;

  /// No description provided for @kaspiPayTitle.
  ///
  /// In en, this message translates to:
  /// **'Kaspi payment'**
  String get kaspiPayTitle;

  /// No description provided for @kaspiAmountToPay.
  ///
  /// In en, this message translates to:
  /// **'To pay: {amount}'**
  String kaspiAmountToPay(String amount);

  /// No description provided for @kaspiScanOrPay.
  ///
  /// In en, this message translates to:
  /// **'Scan the QR code or tap «Pay» to open Kaspi'**
  String get kaspiScanOrPay;

  /// No description provided for @kaspiWaitingPayment.
  ///
  /// In en, this message translates to:
  /// **'Waiting for payment…'**
  String get kaspiWaitingPayment;

  /// No description provided for @kaspiPaymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment failed'**
  String get kaspiPaymentFailed;

  /// No description provided for @kaspiLinkExpired.
  ///
  /// In en, this message translates to:
  /// **'The payment link has expired'**
  String get kaspiLinkExpired;

  /// No description provided for @kaspiPayAgain.
  ///
  /// In en, this message translates to:
  /// **'Pay again'**
  String get kaspiPayAgain;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'kk', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'kk': return AppLocalizationsKk();
    case 'ru': return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
