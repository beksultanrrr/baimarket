import 'package:bai_market/core/providers/language_provider.dart';
import 'package:bai_market/features/app_update/presentation/cubit/app_update_cubit.dart';
import 'package:bai_market/features/app_update/presentation/widgets/app_update_gate.dart';
import 'package:bai_market/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:bai_market/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:bai_market/features/cart/presentation/widgets/cart_event_listener.dart';
import 'package:bai_market/features/cart/presentation/widgets/cart_floating_bar_host.dart';
import 'package:bai_market/features/catalog/presentation/cubit/catalog_cubit.dart';
import 'package:bai_market/features/collection/presentation/cubit/collection_cubit.dart';
import 'package:bai_market/features/create_order/presentation/cubit/create_order_cubit.dart';
import 'package:bai_market/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:bai_market/features/get_slug_list/presentation/cubit/slug_cubit.dart';
import 'package:bai_market/features/notification/presentation/cubit/notification_cubit.dart';
import 'package:bai_market/features/orders/presentation/cubit/orders_cubit.dart';
import 'package:bai_market/features/product/presentation/cubit/product_cubit.dart';
import 'package:bai_market/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

import 'core/firebase_service.dart';
import 'core/push/push_gate.dart';
import 'core/ui/root_messenger.dart';
import 'core/routing/app_routing.dart';
import 'l10n/app_localizations.dart';
import 'package:bai_market/features/profile/presentation/cubit/current_user_cubit.dart';
import 'package:bai_market/features/live/presentation/cubit/live_host_cubit.dart';

void main() async {
  try {
    WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

    // Увеличиваем кэш декодированных изображений до 150 МБ (по умолчанию ~100 МБ)
    PaintingBinding.instance.imageCache.maximumSizeBytes = 150 * 1024 * 1024;

    // Initialize Firebase first
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Then initialize Firebase Messaging with retry logic
    int retryCount = 0;
    const maxRetries = 3;
    bool initialized = false;

    while (!initialized && retryCount < maxRetries) {
      try {
        await FirebaseMessagingService.init();
        initialized = true;
      } catch (e) {
        print(
          'Error initializing Firebase Messaging, attempt ${retryCount + 1} of $maxRetries: $e',
        );
        if (retryCount < maxRetries - 1) {
          await Future.delayed(const Duration(seconds: 2));
        }
        retryCount++;
      }
    }

    if (!initialized) {
      print(
        'Failed to initialize Firebase Messaging after $maxRetries attempts',
      );
    }

    runApp(const riverpod.ProviderScope(child: MainApp()));
  } catch (e) {
    print('Error during app initialization: $e');
    // You might want to show an error screen or handle the error appropriately
    runApp(
      MaterialApp(
        home: Scaffold(body: Center(child: Text('Error initializing app: $e'))),
      ),
    );
  } finally {
    FlutterNativeSplash.remove();
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  void initState() {
    FlutterNativeSplash.remove();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        BlocProvider(create: (context) => CatalogCubit()),
        BlocProvider(create: (context) => SlugCubit()),
        BlocProvider(create: (context) => ProductCubit()),
        BlocProvider(create: (context) => ProfileCubit()),
        // Роль нужна вне экрана профиля (вкладка «Эфиры»), живёт всю
        // сессию и меняется только на входе/выходе.
        BlocProvider(create: (context) => CurrentUserCubit()..ensureLoaded()),
        // Один экземпляр на всё приложение: «идёт ли у меня эфир» читают и
        // вкладка «Эфиры», и экран ведущего, который этот эфир завершает.
        BlocProvider(create: (context) => LiveHostCubit()),
        BlocProvider(create: (context) => CollectionCubit()),
        BlocProvider(create: (context) => FavoritesCubit()),
        BlocProvider(create: (context) => CartCubit()),
        BlocProvider(create: (context) => AuthCubit()),
        BlocProvider(create: (context) => CreateOrderCubit()),
        BlocProvider(create: (context) => OrdersCubit()),
        BlocProvider(create: (context) => NotificationCubit()),
        BlocProvider(create: (context) => AppUpdateCubit()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: MaterialApp.router(
              // Видно в списке недавних приложений на Android.
              title: 'hibai',
              debugShowCheckedModeBanner: false,
              // Мессенджер выше навигатора роутера и всех оверлеев: снекбары
              // экранов показываем только через него, иначе шит эфира
              // оставляет протухшую регистрацию Scaffold и showSnackBar
              // падает. См. [rootMessengerKey].
              scaffoldMessengerKey: rootMessengerKey,
              theme: ThemeData(
                primarySwatch: Colors.green,
                fontFamily: 'Inter',
              ),
              routerConfig: router,
              // Единственная точка выше навигатора роутера: и сообщения
              // корзины, и её плашка должны переживать любой push.
              //
              // AppUpdateGate — самый внешний слой намеренно: диалог
              // обязательного обновления обязан лежать поверх всего, включая
              // плашку корзины и шиты эфира.
              builder: (context, child) => AppUpdateGate(
                child: PushGate(
                  child: CartEventListener(
                    child: CartFloatingBarHost(
                      child: child ?? const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('en'), // English
                Locale('ru'), // Russian
                Locale('kk'), // Kazakh
              ],
              locale: languageProvider.currentLocale,
            ),
          );
        },
      ),
    );
  }
}
