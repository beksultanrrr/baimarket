part of 'seller_list_cubit.dart';

enum SellerListStatus { initial, loading, loaded, error }

class SellerListState extends Equatable {
  const SellerListState({
    this.status = SellerListStatus.initial,
    this.sellers = const [],
  });

  final SellerListStatus status;
  final List<SellerModel> sellers;

  SellerListState copyWith({
    SellerListStatus? status,
    List<SellerModel>? sellers,
  }) {
    return SellerListState(
      status: status ?? this.status,
      sellers: sellers ?? this.sellers,
    );
  }

  @override
  List<Object?> get props => [status, sellers];
}
