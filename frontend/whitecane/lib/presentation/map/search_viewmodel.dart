import 'package:get/get.dart';
import 'package:whitecane/data/local/mock_building_data.dart';
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

    // 로컬 건물 데이터에서 먼저 매칭 (네이버 결과 앞에 노출)
    final localResults = MockBuildingData.getMatchingBuildings(query);

    _isLoading.value = true;
    _error.value = '';

    try {
      final remoteResults = await _searchPlacesUseCase.execute(query);
      _places.assignAll([...localResults, ...remoteResults]);
    } catch (e) {
      // 네트워크 오류 시에도 로컬 결과는 표시
      _places.assignAll(localResults);
      if (localResults.isEmpty) {
        _error.value = '검색 중 오류 발생: ${e.toString()}';
      }
    } finally {
      _isLoading.value = false;
    }
  }
}
