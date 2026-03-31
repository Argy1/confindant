import 'package:confindant/features/home/data/home_data_source.dart';
import 'package:confindant/features/home/models/home_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final homeViewModelProvider =
    StateNotifierProvider<HomeViewModel, HomeScreenState>((ref) {
      return HomeViewModel(ref.watch(homeDataSourceProvider));
    });

class HomeViewModel extends StateNotifier<HomeScreenState> {
  HomeViewModel(this._dataSource) : super(HomeScreenState.initial()) {
    load();
  }

  final HomeDataSource _dataSource;

  Future<void> load() async {
    try {
      final data = await _dataSource.fetch();
      final isEmpty =
          data.recentTransactions.isEmpty && data.budgetItems.isEmpty;
      state = state.copyWith(
        data: data,
        uiState: isEmpty ? HomeUiState.empty : HomeUiState.loaded,
        clearError: true,
      );
    } catch (_) {
      state = state.copyWith(
        uiState: HomeUiState.error,
        errorMessage: 'Unable to load dashboard right now.',
      );
    }
  }
}
