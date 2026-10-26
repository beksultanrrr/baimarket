import 'package:bai_market/features/product/data/datasources/product_services.dart';
import 'package:bai_market/features/product/data/models/product_model.dart';
import 'package:bai_market/features/product/domain/repositories/product_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'product_state.dart';

class ProductCubit extends Cubit<ProductState> {
  final ProductRepository _productRepository;
  ProductCubit({ProductRepository? productRepository})
    : _productRepository = productRepository ?? ProductServices(),
      super(ProductInitial());

  Future<void> getProductDetail({required int id}) async {
    emit(ProductGetting());
    try {
      final result = await _productRepository.getProductDetail(id: id);
      switch (result) {
        case ProductDetailLoaded(:final product):
          emit(ProductGot(productModel: product));
        case ProductDetailNotFound():
          emit(ProductNotFound());
        case ProductDetailFailed():
          emit(ProductGetError());
      }
    } catch (e) {
      emit(ProductGetError());
    }
  }
}
