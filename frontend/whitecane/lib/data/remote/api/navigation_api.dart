import 'package:dio/dio.dart';
import 'package:whitecane/data/remote/dto/navigation_dto.dart';

class NavigationApi {
  final Dio _dio;
  final String _baseUrl;

  NavigationApi(this._dio, {required String baseUrl}) : _baseUrl = baseUrl;

  /// 경로 계산
  Future<RouteResponseDto> calculateRoute(RouteRequestDto request) async {
    final response = await _dio.post(
      '${_baseUrl}api/navigation/route',
      data: request.toJson(),
    );
    return RouteResponseDto.fromJson(response.data as Map<String, dynamic>);
  }

  /// node_id로 좌표 조회 (포인트 노드)
  Future<CoordinateDto> getNodeCoordinates(String nodeId) async {
    final response = await _dio
        .get('${_baseUrl}api/navigation/node_coordinates/$nodeId');
    return CoordinateDto.fromJson(response.data as Map<String, dynamic>);
  }

  /// node_id로 건물 폴리곤 중심 좌표 조회
  Future<CoordinateDto> getNodePolygonCoordinates(String nodeId) async {
    final response = await _dio
        .get('${_baseUrl}api/navigation/polygon_center/$nodeId');
    return CoordinateDto.fromJson(response.data as Map<String, dynamic>);
  }
}
