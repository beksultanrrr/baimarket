import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/app_pallete.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/order_model.dart';
import '../cubit/orders_cubit.dart';
import '../widgets/order_card.dart';
import '../widgets/order_filter.dart';
import '../widgets/orders_empty_state.dart';
import '../widgets/orders_filter_tabs.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late final OrdersCubit _cubit = OrdersCubit()..getOrders();
  OrderFilter _filter = OrderFilter.all;

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _goToShopping() => context.go('/catalog');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(32, 32),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/profile');
              }
            },
            child: SvgPicture.asset(
              'assets/icons/arrow_left.svg',
              height: 20,
              width: 20,
            ),
          ),
        ),
        title: Text(
          l10n.myOrders,
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: BlocBuilder<OrdersCubit, OrdersState>(
          bloc: _cubit,
          builder: (context, state) {
            return Column(
              children: [
                const SizedBox(height: 8),
                OrdersFilterTabs(
                  selected: _filter,
                  onSelected: (f) => setState(() => _filter = f),
                ),
                const SizedBox(height: 16),
                Expanded(child: _buildBody(state)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(OrdersState state) {
    if (state is OrdersGetting) {
      return const Center(
        child: CircularProgressIndicator(color: mainColorLight),
      );
    }
    if (state is OrdersGetError) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: OrdersEmptyState(onGoShopping: _goToShopping),
      );
    }
    if (state is OrdersGot) return _list(state.orders);
    return const SizedBox.shrink();
  }

  Widget _list(List<OrderModel> orders) {
    final filtered =
        orders.where((o) => orderMatchesFilter(_filter, o.status)).toList();
    if (filtered.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: OrdersEmptyState(onGoShopping: _goToShopping),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final order = filtered[index];
        return OrderCard(
          order: order,
          onTap: () => context.push('/order', extra: order),
          // TODO(reviews): отзывы временно отключены целиком.
          // onLeaveReview: () {},
        );
      },
    );
  }
}
