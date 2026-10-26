import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../cards/data/models/payment_card_model.dart';
import '../cubit/payment_cubit.dart';
import 'delete_card_dialog.dart';
import 'other_card_tile.dart';
import 'select_card_tile.dart';
import 'sheet_close_button.dart';
import '../../../live/presentation/widgets/live_shopping_scope.dart';

/// Возвращаемые из шита намерения родительскому экрану.
enum SelectCardResult { picked, addNewCard }

/// Открывает шит выбора сохранённой карты. Возвращает [SelectCardResult]
/// либо `null`, если шит был закрыт без действия.
Future<SelectCardResult?> showSelectCardSheet({
  required BuildContext context,
  required PaymentCubit paymentCubit,
}) {
  return showModalBottomSheet<SelectCardResult>(
    context: context,
    routeSettings: const RouteSettings(name: kLiveSheetRouteName),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return BlocProvider.value(
        value: paymentCubit,
        child: const _SelectCardSheet(),
      );
    },
  );
}

class _SelectCardSheet extends StatelessWidget {
  const _SelectCardSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF5F5F5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.fromTitle,
                        style: const TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    SheetCloseButton(onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              Expanded(
                child: BlocBuilder<PaymentCubit, PaymentState>(
                  builder: (context, state) {
                    final s = state as PaymentReady;
                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: s.cards.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        if (index < s.cards.length) {
                          final card = s.cards[index];
                          return SelectCardTile(
                            card: card,
                            onTap: () {
                              context.read<PaymentCubit>().selectCard(card.id);
                              Navigator.pop(context, SelectCardResult.picked);
                            },
                            onRemove: () => _confirmRemove(context, card),
                          );
                        }
                        return OtherCardTile(
                          onTap: () => Navigator.pop(
                            context,
                            SelectCardResult.addNewCard,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    PaymentCardModel card,
  ) async {
    final confirmed = await showDeleteCardDialog(context);
    if (confirmed == true && context.mounted) {
      context.read<PaymentCubit>().removeCard(card.id);
    }
  }
}
