import 'package:bai_market/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:bai_market/features/support/presentation/pages/support_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/auth/sign_out.dart';
import '../../../../core/firebase_service.dart';
import '../../../../core/ui/root_messenger.dart';
import '../../../../core/urls.dart';
import '../../../../core/widgets/app_refresh_indicator.dart';
import '../widgets/app_version_label.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../widgets/profile_cart_banner.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_invite_banner.dart';
import '../widgets/profile_language_selector.dart';
import '../widgets/profile_menu_item.dart';
import '../widgets/profile_user_card.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  /// Разрешены ли уведомления системой — подпись пункта меню. `null` пока
  /// не проверено.
  bool? _pushAllowed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProfileCubit>().getProfileData();
      context.read<CartCubit>().getCart();
      _refreshPushStatus();
    });
  }

  Future<void> _refreshPushStatus() async {
    final allowed = await FirebaseMessagingService.isAllowed();
    if (!mounted) return;
    setState(() => _pushAllowed = allowed);
  }

  Future<void> _onRefresh() async {
    await Future.wait([context.read<ProfileCubit>().getProfileData(), context.read<CartCubit>().getCart(), _refreshPushStatus()]);
  }

  /// «Мои билеты» ведут во внешний кабинет Satty juldyz, а не на внутренний
  /// экран `/tickets`. Открываем во внешнем браузере, как и остальные внешние
  /// ссылки приложения.
  Future<void> _openSattyJuldyz() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final ok = await launchUrl(Uri.parse(sattyJuldyzLoginUrl), mode: LaunchMode.externalApplication);
      if (ok) return;
    } catch (_) {
      // Открывать нечем — ниже покажем снекбар.
    }
    showRootSnackBar(
      SnackBar(content: Text(l10n.failedToOpen('sz.kz')), backgroundColor: Colors.redAccent),
      fallbackContext: mounted ? context : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        if (state is ProfileGetError) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5F5F5),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.error(''),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.black54, fontFamily: 'Gilroy'),
                    ),
                    const SizedBox(height: 16),
                    CupertinoButton(
                      onPressed: () => context.read<ProfileCubit>().getProfileData(),
                      child: Text(l10n.confirm, style: const TextStyle(fontFamily: 'Gilroy')),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        if (state is ProfileGot) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5F5F5),
            body: AppRefreshIndicator(
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                child: Column(
                  children: [
                    // По макету экран собран не из карточек с отступами, а из
                    // трёх белых секций во всю ширину, разделённых серым фоном.
                    Container(
                      width: double.infinity,
                      color: Colors.white,
                      child: Column(
                        children: [
                          const ProfileHeader(),
                          ProfileUserCard(profile: state.profile),
                          const ProfileCartBanner(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      color: Colors.white,
                      child: Column(
                        children: [
                          ProfileMenuItem(
                            svgAsset: 'assets/icons/like.svg',
                            title: l10n.favorites,
                            subtitle: '${state.profile.favoritesCount ?? 0} ${l10n.products}',
                            onTap: () => context.push('/favorites'),
                          ),
                          ProfileMenuItem(
                            svgAsset: 'assets/icons/profile_page/ticket-star.svg',
                            title: l10n.myTickets,
                            subtitle: l10n.sattyJuldyz,
                            onTap: _openSattyJuldyz,
                          ),
                          ProfileMenuItem(
                            svgAsset: 'assets/icons/profile_page/location-2.svg',
                            title: l10n.myAddresses,
                            subtitle: l10n.specifyDeliveryAddress,
                            onTap: () => context.push('/my_address'),
                          ),
                          ProfileMenuItem(
                            svgAsset: 'assets/icons/profile_page/bag.svg',
                            title: l10n.myOrders,
                            subtitle: l10n.orderStatus,
                            onTap: () => context.push('/orders'),
                          ),
                          // TODO(cards): «Мои карты» временно убраны из меню.
                          // Экран и маршрут `/my_cards` на месте — чтобы
                          // вернуть пункт, достаточно раскомментировать.
                          // ProfileMenuItem(
                          //   svgAsset: 'assets/icons/profile_page/profile_page_card.svg',
                          //   title: l10n.myCard,
                          //   subtitle: l10n.orderStatus,
                          //   onTap: () => context.push('/my_cards'),
                          //   showDivider: true,
                          // ),
                          ProfileMenuItem(
                            svgAsset: 'assets/icons/profile_page/headphone.svg',
                            title: l10n.contacts,
                            subtitle: l10n.techSupport,
                            onTap: () {
                              showModalBottomSheet(elevation: 0, backgroundColor: Colors.white, isScrollControlled: true, useSafeArea: true, context: context, builder: (_) => const SupportPage());
                            },
                          ),
                          ProfileMenuItem(
                            svgAsset: 'assets/icons/profile_page/headphone.svg',
                            title: l10n.notificationsSettingsTitle,
                            subtitle: _pushAllowed == null ? '' : (_pushAllowed! ? l10n.notificationsOn : l10n.notificationsOff),
                            onTap: FirebaseMessagingService.openSystemSettings,
                            // Скрытый вход в диагностику пушей — им пользуется
                            // разработчик, обычному пользователю он не нужен.
                            onLongPress: () => context.push('/debug/push'),
                          ),
                          const ProfileLanguageSelector(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const ProfileInviteBanner(),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      color: Colors.white,
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => _confirmLogout(context, l10n),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 26,
                                height: 26,
                                // По макету «Выйти» оформлен как обычный пункт:
                                // зелёная иконка и чёрная подпись, а не красный
                                // разрушающий стиль. Подтверждение в диалоге
                                // остаётся.
                                child: Center(child: SvgPicture.asset('assets/icons/profile_page/logout.svg', width: 22, height: 22)),
                              ),
                              const SizedBox(width: 14),
                              Text(
                                l10n.logout,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black, fontFamily: 'Gilroy'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      color: Colors.white,
                      child: const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: AppVersionLabel(),
                      ),
                    ),
                    const SizedBox(height: 200),
                  ],
                ),
              ),
            ),
          );
        }
        return const Scaffold(
          backgroundColor: Colors.white,
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  void _confirmLogout(BuildContext context, AppLocalizations l10n) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.exitApp, style: const TextStyle(fontFamily: 'Gilroy')),
        content: Text(l10n.exitConfirmation, style: const TextStyle(fontFamily: 'Gilroy')),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel, style: const TextStyle(fontFamily: 'Gilroy')),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(ctx).pop();
              await signOutAndCleanup(context);
            },
            child: Text(l10n.logout, style: const TextStyle(fontFamily: 'Gilroy')),
          ),
        ],
      ),
    );
  }
}
