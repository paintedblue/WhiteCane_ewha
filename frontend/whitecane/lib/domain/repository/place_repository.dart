import 'package:whitecane/data/remote/api/building_api.dart';
import 'package:whitecane/domain/model/place.dart';

abstract class PlaceRepository {
  Future<List<Place>> searchByName(String name);
  Future<List<Place>> searchByCategory(String category);
}

class PlaceRepositoryImpl implements PlaceRepository {
  final BuildingApi buildingApi;

  PlaceRepositoryImpl({required this.buildingApi});

  @override
  Future<List<Place>> searchByName(String name) async {
    final results = await buildingApi.searchByName(name);
    return results
        .map((dto) => Place(
              nodeId: dto.nodeId,
              id: dto.buildingId,
              placeName: dto.name,
              category: dto.category,
              contact: dto.phoneNumber ?? '없음',
              alias: dto.alias,
            ))
        .toList();
  }

  @override
  Future<List<Place>> searchByCategory(String category) async {
    final results = await buildingApi.searchByCategory(category);
    return results
        .map((dto) => Place(
              nodeId: dto.nodeId,
              id: dto.buildingId,
              placeName: dto.name,
              category: dto.category,
              contact: dto.phoneNumber ?? '없음',
              alias: dto.alias,
            ))
        .toList();
  }
}
