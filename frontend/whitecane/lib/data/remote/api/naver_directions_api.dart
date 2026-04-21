import 'package:dio/dio.dart';
import 'package:whitecane/data/remote/dto/directions_dto.dart';

class NaverDirectionsApi {
  final Dio _dio;
  final String _clientId;
  final String _clientSecret;

  static const String _url =
      'https://naveropenapi.apigw.ntruss.com/map-direction-15/walking';

  NaverDirectionsApi(
    this._dio, {
    required String clientId,
    required String clientSecret,
  })  : _clientId = clientId,
        _clientSecret = clientSecret;

  /// 보행자 경로 조회 (Directions 15 Walking)
  Future<DirectionsResponseDto> getRoute({
    required double startLat,
    required double startLng,
    required double goalLat,
    required double goalLng,
  }) async {
    final response = await _dio.get(
      _url,
      queryParameters: {
        'start': '$startLng,$startLat', // Directions API는 경도,위도 순
        'goal': '$goalLng,$goalLat',
      },
      options: Options(
        headers: {
          'x-ncp-apigw-api-key-id': _clientId,
          'x-ncp-apigw-api-key': _clientSecret,
        },
      ),
    );
    return DirectionsResponseDto.fromJson(
        response.data as Map<String, dynamic>);
  }
}
