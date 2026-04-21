import 'package:whitecane/data/remote/api/naver_local_search_api.dart';
import 'package:whitecane/domain/model/place.dart';

abstract class PlaceRepository {
  Future<List<Place>> searchByName(String name);
}

class PlaceRepositoryImpl implements PlaceRepository {
  final NaverLocalSearchApi naverLocalSearchApi;

  PlaceRepositoryImpl({required this.naverLocalSearchApi});

  @override
  Future<List<Place>> searchByName(String name) =>
      naverLocalSearchApi.search(name);
}
