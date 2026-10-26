import 'package:bai_market/core/app_pallete.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/auth/auth_gate.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/repositories/reviews_repository.dart';
import '../cubit/reviews_cubit.dart';
import '../../../live/presentation/widgets/live_shopping_scope.dart';

/// Шит написания отзыва.
///
/// Звёзд намеренно нет: в макете рейтинга не предусмотрено, поле `rating` в
/// контракте заведено на будущее — отправляем `null`.
///
/// Гостей отсекаем `ensureAuthenticated` до открытия шита: `POST` требует JWT,
/// и лучше показать шит логина, чем ловить 401 после набора текста.
Future<void> showReviewComposerSheet({
  required BuildContext context,
  required int modelId,
  required ReviewsCubit cubit,
}) async {
  final ok = await ensureAuthenticated(context);
  if (!ok || !context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    routeSettings: const RouteSettings(name: kLiveSheetRouteName),
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetCtx) => BlocProvider.value(
      value: cubit,
      child: _ReviewComposer(modelId: modelId),
    ),
  );
}

class _ReviewComposer extends StatefulWidget {
  const _ReviewComposer({required this.modelId});

  final int modelId;

  @override
  State<_ReviewComposer> createState() => _ReviewComposerState();
}

class _ReviewComposerState extends State<_ReviewComposer> {
  final _controller = TextEditingController();

  /// Блокируем кнопку и некоторое время после успеха: лимит на создание —
  /// 5 запросов в минуту, двойной тап легко сожжёт 429.
  bool _justSent = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final cubit = context.read<ReviewsCubit>();
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _justSent = true);
    final result = await cubit.submit(modelId: widget.modelId, text: text);
    if (!mounted) return;

    final (message, isError) = switch (result) {
      CreateReviewSuccess() => (l10n.reviewSubmitted, false),
      CreateReviewAlreadyExists() => (l10n.reviewAlreadyLeft, true),
      CreateReviewRateLimited() => (l10n.reviewTooManyRequests, true),
      CreateReviewProductMissing() => (l10n.productUnavailable, true),
      CreateReviewUnauthorized() => (l10n.reviewSubmitError, true),
      CreateReviewFailed() => (l10n.reviewSubmitError, true),
    };

    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : darkButtonColor,
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (result is CreateReviewSuccess) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _justSent = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      // Поднимаем над клавиатурой.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: BlocBuilder<ReviewsCubit, ReviewsState>(
            builder: (context, state) {
              final busy = state.submitting || _justSent;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.orderLeaveReview,
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controller,
                    maxLines: 4,
                    minLines: 4,
                    maxLength: 1000,
                    enabled: !busy,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: l10n.reviewComposerHint,
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      borderRadius: BorderRadius.circular(16),
                      color: mainColorLight,
                      onPressed: busy || _controller.text.trim().isEmpty
                          ? null
                          : _submit,
                      child: busy
                          ? const CupertinoActivityIndicator(
                              color: Colors.white,
                            )
                          : Text(
                              l10n.reviewSend,
                              style: const TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
