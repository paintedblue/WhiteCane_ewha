import 'package:dio/dio.dart';
import 'package:whitecane/data/remote/dto/building_dto.dart';

class BuildingApi {
  final Dio _dio;
  final String _baseUrl;

  BuildingApi(this._dio, {required String baseUrl}) : _baseUrl = baseUrl;

  /// 건물 이름으로 검색
  Future<List<BuildingResponseDto>> searchByName(String name) async {
    final response = await _dio.get(
      '${_baseUrl}api/building',
      queryParameters: {'name': name},
    );
    return (response.data as List)
        .map((e) => BuildingResponseDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 카테고리로 건물 검색
  Future<List<BuildingResponseDto>> searchByCategory(String category) async {
    final response = await _dio.get(
      '${_baseUrl}api/building/category',
      queryParameters: {'category': category},
    );
    return (response.data as List)
        .map((e) => BuildingResponseDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// node_id로 건물 상세 조회
  Future<BuildingFullResponseDto?> getBuildingByNodeId(String nodeId) async {
    final response = await _dio.get('${_baseUrl}api/buildings_node/$nodeId');
    if (response.data == null) return null;
    return BuildingFullResponseDto.fromJson(
        response.data as Map<String, dynamic>);
  }
}
