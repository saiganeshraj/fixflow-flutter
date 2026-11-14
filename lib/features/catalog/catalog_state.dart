import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ServiceSort {
  recommended('Recommended'),
  priceLow('Price: low to high'),
  priceHigh('Price: high to low');

  final String label;
  const ServiceSort(this.label);
}

/// One immutable source of truth for the catalog controls.
class CatalogFilters {
  final String query;
  final String? categoryId;
  final ServiceSort sort;
  const CatalogFilters({
    this.query = '',
    this.categoryId,
    this.sort = ServiceSort.recommended,
  });

  bool get hasFilters => query.trim().isNotEmpty || categoryId != null;
}

final catalogFiltersProvider =
    NotifierProvider<CatalogFiltersController, CatalogFilters>(
      CatalogFiltersController.new,
    );

class CatalogFiltersController extends Notifier<CatalogFilters> {
  @override
  CatalogFilters build() => const CatalogFilters();

  void search(String query) => state = CatalogFilters(
    query: query,
    categoryId: state.categoryId,
    sort: state.sort,
  );
  void selectCategory(String? id) => state = CatalogFilters(
    query: state.query,
    categoryId: id,
    sort: state.sort,
  );
  void sortBy(ServiceSort sort) => state = CatalogFilters(
    query: state.query,
    categoryId: state.categoryId,
    sort: sort,
  );
  void reset() => state = const CatalogFilters();
}
