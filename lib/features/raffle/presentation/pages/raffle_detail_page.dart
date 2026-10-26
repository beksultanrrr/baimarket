import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/app_pallete.dart';
import '../../../../core/widgets/shimmer.dart';
import '../../../../l10n/app_localizations.dart';
import '../cubit/raffle_detail_cubit.dart';
import '../widgets/raffle_detail_header.dart';
import '../widgets/raffle_gifts_sheet.dart';
import '../widgets/raffle_products_section.dart';

class RaffleDetailPage extends StatefulWidget {
  const RaffleDetailPage({super.key, required this.id, this.titleOverride});

  final int id;
  final String? titleOverride;

  @override
  State<RaffleDetailPage> createState() => _RaffleDetailPageState();
}

class _RaffleDetailPageState extends State<RaffleDetailPage> {
  late final RaffleDetailCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = RaffleDetailCubit()..load(id: widget.id);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: mainColorLight,
        body: BlocProvider.value(
          value: _cubit,
          child: BlocBuilder<RaffleDetailCubit, RaffleDetailState>(
            builder: (context, state) {
              if (state.status == RaffleDetailStatus.error &&
                  state.raffle == null) {
                return _ErrorView(onRetry: () => _cubit.load(id: widget.id));
              }
              if (state.raffle == null) {
                return const _LoadingView();
              }
              return _Loaded(
                id: widget.id,
                state: state,
                titleOverride: widget.titleOverride,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({required this.id, required this.state, this.titleOverride});

  final int id;
  final RaffleDetailState state;
  final String? titleOverride;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RaffleDetailCubit>();
    final raffle = state.raffle!;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: RaffleDetailHeader(
            raffle: raffle,
            titleOverride: titleOverride,
            onGiftsTap: () => showRaffleGiftsSheet(
              context: context,
              gifts: raffle.gifts,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: RaffleProductsSection(
            products: state.products,
            sort: state.sort,
            isSorting: state.status == RaffleDetailStatus.sorting,
            onSortChanged: (sort) => cubit.changeSort(id: id, sort: sort),
          ),
        ),
      ],
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              height: 160,
              child: SimpleShimmer(borderRadius: 16),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(20),
              child: GridView.builder(
                itemCount: 4,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 342,
                ),
                itemBuilder: (_, __) =>
                    const SimpleShimmer(borderRadius: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.raffleLoadError,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => _pop(context),
                    child: Text(
                      l10n.goToShopping,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  TextButton(
                    onPressed: onRetry,
                    child: Text(
                      l10n.tryAgain,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _pop(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/catalog');
    }
  }
}
