import 'package:dio/dio.dart';
import 'package:whitecane/data/remote/dto/building_dto.dart';

class BuildingApi {
  final Dio _dio;
  final String _baseUrl;

  BuildingApi(this._dio, {required String baseUrl}) : _baseUrl = baseUrl;

  Future<List<BuildingResponseDto>> searchByName(String name) async {
    final response = await _dio.get(
      '${_baseUrl}api/building',
      queryParameters: {'name': name},
    );
    return (response.data as List)
        .map((e) => BuildingResponseDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
