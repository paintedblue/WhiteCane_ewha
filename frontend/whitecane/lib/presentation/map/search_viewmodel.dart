import 'package:get/get.dart';
import 'package:whitecane/domain/model/place.dart';
import 'package:whitecane/domain/usecase/search_places_usecase.dart';

class SearchViewModel extends GetxController {
  final SearchPlacesUseCase _searchPlacesUseCase;

  final RxList<Place> _places = <Place>[].obs;
  final RxString _error = ''.obs;
  final RxBool _isLoading = false.obs;

  List<Place> get places => _places;
  String get error => _error.value;
  bool get isLoading => _isLoading.value;

  SearchViewModel({required SearchPlacesUseCase searchPlacesUseCase})
      : _searchPlacesUseCase = searchPlacesUseCase;

  Future<void> searchPlaces(String query) async {
    if (query.isEmpty) {
      _places.clear();
      return;
    }

    _isLoading.value = true;
    _error.value = '';

    try {
      final results = await _searchPlacesUseCase.execute(query);
      _places.assignAll(results);
    } catch (e) {
      _error.value = '검색 중 오류 발생: ${e.toString()}';
    } finally {
      _isLoading.value = false;
    }
  }
}
