import 'package:whitecane/domain/model/place.dart';
import 'package:whitecane/domain/repository/place_repository.dart';

class SearchPlacesUseCase {
  final PlaceRepository repository;

  SearchPlacesUseCase({required this.repository});

  Future<List<Place>> execute(String query) async {
    if (query.isEmpty) return [];
    return repository.searchByName(query);
  }
}
