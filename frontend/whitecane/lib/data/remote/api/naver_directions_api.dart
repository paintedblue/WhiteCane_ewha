import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:whitecane/data/remote/dto/directions_dto.dart';

enum TransportMode { walking, car }

/// 이동 수단에 따라 OSRM(도보) / Kakao Mobility(자동차) API를 분기
class NaverDirectionsApi {
  final Dio _dio;
  final String _kakaoApiKey;

  static const _osrmUrl = 'https://router.project-osrm.org/route/v1/foot';
  static const _kakaoCarUrl =
      'https://apis-navi.kakaomobility.com/v1/directions';

  NaverDirectionsApi(
    this._dio, {
    String clientId = '',
    String clientSecret = '',
    String kakaoApiKey = '',
  }) : _kakaoApiKey = kakaoApiKey;

  Future<DirectionsResponseDto> getRoute({
    required double startLat,
    required double startLng,
    required double goalLat,
    required double goalLng,
    TransportMode mode = TransportMode.walking,
  }) async {
    return mode == TransportMode.walking
        ? _osrmWalking(startLat, startLng, goalLat, goalLng)
        : _kakaoCar(startLat, startLng, goalLat, goalLng);
  }

  Future<DirectionsResponseDto> _osrmWalking(
      double startLat, double startLng, double goalLat, double goalLng) async {
    final url = '$_osrmUrl/$startLng,$startLat;$goalLng,$goalLat';
    final response = await _dio.get(
      url,
      queryParameters: {'overview': 'full', 'geometries': 'geojson'},
      options: Options(validateStatus: (s) => s != null),
    );
    debugPrint('[OSRM walking] status=${response.statusCode}');
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      return const DirectionsResponseDto(code: -1, message: '잘못된 응답');
    }
    return DirectionsResponseDto.fromOsrmJson(data);
  }

  Future<DirectionsResponseDto> _kakaoCar(
      double startLat, double startLng, double goalLat, double goalLng) async {
    final response = await _dio.get(
      _kakaoCarUrl,
      queryParameters: {
        'origin': '$startLng,$startLat',
        'destination': '$goalLng,$goalLat',
        'priority': 'RECOMMEND',
      },
      options: Options(
        headers: {'Authorization': 'KakaoAK $_kakaoApiKey'},
        validateStatus: (s) => s != null,
      ),
    );
    debugPrint('[Kakao car] status=${response.statusCode}');
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      return const DirectionsResponseDto(code: -1, message: '잘못된 응답');
    }
    return DirectionsResponseDto.fromKakaoJson(data);
  }
}
