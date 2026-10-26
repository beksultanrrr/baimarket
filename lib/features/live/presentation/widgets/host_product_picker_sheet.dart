import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/urls.dart';
import '../../../../core/widgets/show_image.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../catalog/data/models/category_product_model.dart';
import '../../../seller/data/datasources/seller_services.dart';
import '../../../seller/domain/repositories/seller_repository.dart';
import 'live_shopping_scope.dart';
import 'sheet_close_button.dart';

/// Выбор товара, который ведущий показывает зрителям.
///
/// Список — собственная витрина продавца (`GET /seller/:id/models`). Своей роли
/// и своего sellerId клиент не знает: единственный источник — `sellerId` в теле
/// ответа `POST /live/start`.
Future<void> showHostProductPickerSheet({
  required BuildContext context,
  required int sellerId,
  required ValueChanged<int> onPick,
  required VoidCallback onUnpin,
  int? pinnedProductId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    routeSettings: const RouteSettings(name: kLiveSheetRouteName),
    builder: (sheetCtx) => _HostProductPickerSheet(
      sellerId: sellerId,
      pinnedProductId: pinnedProductId,
      onPick: onPick,
      onUnpin: onUnpin,
    ),
  );
}

class _HostProductPickerSheet extends StatefulWidget {
  const _HostProductPickerSheet({
    required this.sellerId,
    required this.onPick,
    required this.onUnpin,
    this.pinnedProductId,
  });

  final int sellerId;
  final int? pinnedProductId;
  final ValueChanged<int> onPick;
  final VoidCallback onUnpin;

  @override
  State<_HostProductPickerSheet> createState() =>
      _HostProductPickerSheetState();
}

class _HostProductPickerSheetState extends State<_HostProductPickerSheet> {
  final SellerRepository _repo = SellerServices();
  List<CategoryProductModel>? _products;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await _repo.getSellerProducts(
      id: widget.sellerId,
      sort: 'popular',
      limit: 20,
      skip: 0,
    );
    if (!mounted) return;
    switch (result) {
      case SellerProductsLoaded(:final data):
        setState(() => _products = data.models);
      case SellerProductsNotFound():
      case SellerProductsFailed():
        setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
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
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.hostPickProductTitle,
                        style: const TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    SheetCloseButton(onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              if (widget.pinnedProductId != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        widget.onUnpin();
                        Navigator.pop(context);
                      },
                      child: Container(
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          l10n.hostUnpinProduct,
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFEC1B6E),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Expanded(child: _body(l10n, scrollController)),
            ],
          ),
        );
      },
    );
  }

  Widget _body(AppLocalizations l10n, ScrollController controller) {
    if (_failed) return _Message(text: l10n.streamsLoadError);
    final products = _products;
    if (products == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (products.isEmpty) return _Message(text: l10n.hostNoProducts);

    return ListView.separated(
      controller: controller,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final p = products[i];
        return _ProductRow(
          product: p,
          isPinned: p.id == widget.pinnedProductId,
          pinLabel: l10n.hostPinProduct,
          onPick: () {
            widget.onPick(p.id);
            Navigator.pop(context);
          },
        );
      },
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.product,
    required this.isPinned,
    required this.pinLabel,
    required this.onPick,
  });

  final CategoryProductModel product;
  final bool isPinned;
  final String pinLabel;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final photos = product.photoUrls;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: isPinned ? null : onPick,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isPinned ? const Color(0xFFEFF9E8) : const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: NetworkImageWidget(
                url: (photos != null && photos.isNotEmpty)
                    ? '$imgUrl${photos.first}'
                    : '',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.name ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.price ?? 0}₸',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF71CD32),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isPinned ? '●' : pinLabel,
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isPinned ? const Color(0xFF71CD32) : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 14,
            color: Color(0xFF8C8C8C),
          ),
        ),
      ),
    );
  }
}
