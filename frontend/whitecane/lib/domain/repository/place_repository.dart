import 'package:whitecane/data/remote/api/building_api.dart';
import 'package:whitecane/domain/model/place.dart';

abstract class PlaceRepository {
  Future<List<Place>> searchByName(String name);
}

class PlaceRepositoryImpl implements PlaceRepository {
  final BuildingApi buildingApi;

  PlaceRepositoryImpl({required this.buildingApi});

  @override
  Future<List<Place>> searchByName(String name) async {
    final results = await buildingApi.searchByName(name);
    return results
        .map((dto) => Place(
              placeName: dto.name,
              address: dto.address,
              category: dto.category,
              contact: dto.phoneNumber ?? '',
              latitude: dto.latitude,
              longitude: dto.longitude,
            ))
        .toList();
  }
}
