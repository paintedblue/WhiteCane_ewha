import 'package:whitecane/domain/model/place.dart';
import 'package:whitecane/domain/repository/place_repository.dart';

class SearchPlacesUseCase {
  final PlaceRepository repository;

  SearchPlacesUseCase({required this.repository});

  Future<List<Place>> execute(String query) async {
    if (query.isEmpty) return [];
    final byName = await repository.searchByName(query);
    final byCategory = await repository.searchByCategory(query);
    final unique = {...byName, ...byCategory};
    return unique.toList();
  }
}
