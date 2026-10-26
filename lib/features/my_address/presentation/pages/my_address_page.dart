import 'package:bai_market/core/app_pallete.dart';
import 'package:bai_market/core/widgets/main_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/network/app_dio.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/urls.dart';
import '../../data/datasources/user_address_remote_datasource.dart';
import '../../data/repositories/user_address_repository_impl.dart';
import '../cubit/my_address_cubit.dart';
import '../widgets/add_address_bottom_sheet.dart';
import '../widgets/saved_address_card.dart';

class MyAddressPage extends StatelessWidget {
  const MyAddressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => MyAddressCubit(UserAddressRepositoryImpl(UserAddressRemoteDatasource(appDio, mainUrl)))..loadAddresses(), child: const _MyAddressView());
  }
}

class _MyAddressView extends StatelessWidget {
  const _MyAddressView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: lightGray,
      appBar: AppBar(
        backgroundColor: lightGray,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(onPressed: () => Navigator.of(context).maybePop(), icon: SvgPicture.asset('assets/icons/arrow_left.svg', height: 20, width: 20)),
        title: Text(
          l10n.deliveryAddressesTitle,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<MyAddressCubit, MyAddressState>(
          listener: (context, state) {
            if (state is MyAddressError) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_errorText(l10n, state.kind)), backgroundColor: Colors.red));
            }
          },
          builder: (context, state) {
            return Stack(
              children: [
                _buildContent(context, state),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: _AddAddressButton(
                      onPressed: () async {
                        final added = await AddAddressBottomSheet.show(context);
                        if (added == true && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.addressAdded), backgroundColor: Colors.green));
                        }
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _errorText(AppLocalizations l10n, MyAddressErrorKind kind) {
    switch (kind) {
      case MyAddressErrorKind.load:
        return l10n.addressesLoadError;
      case MyAddressErrorKind.add:
        return l10n.addressAddError;
      case MyAddressErrorKind.delete:
        return l10n.addressDeleteError;
    }
  }

  Widget _buildContent(BuildContext context, MyAddressState state) {
    final l10n = AppLocalizations.of(context)!;
    if (state is MyAddressLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is MyAddressLoaded && state.addresses.isNotEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        itemCount: state.addresses.length,
        itemBuilder: (context, index) {
          final address = state.addresses[index];
          return SavedAddressCard(address: address, onDelete: () => _confirmDelete(context, address.id));
        },
      );
    }
    if (state is MyAddressLoaded && state.addresses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            l10n.noSavedAddresses,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, fontSize: 16),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> _confirmDelete(BuildContext context, int id) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      // Диалог в стиле проекта: скругление 20, Gilroy, разрушающее действие
      // красным. По умолчанию Material рисует radius 4 и системный шрифт.
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n.deleteAddressTitle,
          style: const TextStyle(fontFamily: 'Gilroy', fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black),
        ),
        content: Text(
          l10n.deleteAddressMessage,
          style: const TextStyle(fontFamily: 'Gilroy', fontSize: 15, fontWeight: FontWeight.w400, color: secondaryText, height: 1.3),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              l10n.cancel,
              style: const TextStyle(fontFamily: 'Gilroy', fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.deleteAction,
              style: const TextStyle(fontFamily: 'Gilroy', fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFFE53935)),
            ),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await context.read<MyAddressCubit>().deleteAddress(id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.addressDeleted), backgroundColor: Colors.green));
      }
    }
  }
}

class _AddAddressButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _AddAddressButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    // В макете подпись без плюса.
    return MainButton(textColor: Color(0xFF00520B), onPressed: onPressed, text: AppLocalizations.of(context)!.addMoreAddress, color: mainColorLight);
  }
}
