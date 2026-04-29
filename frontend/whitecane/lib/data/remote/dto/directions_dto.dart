import 'package:whitecane/data/remote/dto/navigation_dto.dart';

class DirectionsSummaryDto {
  final int distance; // 미터
  final int duration; // 밀리초

  const DirectionsSummaryDto({required this.distance, required this.duration});
}

class DirectionsRouteDto {
  final DirectionsSummaryDto summary;
  final List<CoordinateDto> path;

  const DirectionsRouteDto({required this.summary, required this.path});
}

class DirectionsResponseDto {
  final int code;
  final String message;
  final DirectionsRouteDto? route;

  const DirectionsResponseDto({
    required this.code,
    required this.message,
    this.route,
  });

  // ── Kakao Mobility 응답 파싱 (도보) ───────────────────────────────────────
  // routes[0].result_code == 0 이면 성공
  // 좌표: sections[].roads[].vertexes ([lng, lat, lng, lat, ...] 플랫 배열)
  factory DirectionsResponseDto.fromKakaoJson(Map<String, dynamic> json) {
    final routes = json['routes'] as List?;
    if (routes == null || routes.isEmpty) {
      return const DirectionsResponseDto(code: -1, message: '경로 없음');
    }

    final first = routes[0] as Map<String, dynamic>;
    final resultCode = first['result_code'] as int? ?? -1;
    final resultMsg = first['result_msg'] as String? ?? '알 수 없는 오류';

    if (resultCode != 0) {
      return DirectionsResponseDto(code: resultCode, message: resultMsg);
    }

    final summary = first['summary'] as Map<String, dynamic>;
    final distanceM = summary['distance'] as int? ?? 0;
    final durationSec = summary['duration'] as int? ?? 0;

    final List<CoordinateDto> path = [];
    final sections = first['sections'] as List? ?? [];
    for (final section in sections) {
      final roads = (section as Map<String, dynamic>)['roads'] as List? ?? [];
      for (final road in roads) {
        final vertexes = (road as Map<String, dynamic>)['vertexes'] as List? ?? [];
        for (int i = 0; i + 1 < vertexes.length; i += 2) {
          path.add(CoordinateDto(
            latitude: (vertexes[i + 1] as num).toDouble(),
            longitude: (vertexes[i] as num).toDouble(),
          ));
        }
      }
    }

    return DirectionsResponseDto(
      code: 0,
      message: resultMsg,
      route: DirectionsRouteDto(
        summary: DirectionsSummaryDto(
          distance: distanceM,
          duration: durationSec * 1000, // 초 → 밀리초
        ),
        path: path,
      ),
    );
  }

  // ── Naver Directions 5 응답 파싱 (자동차) ────────────────────────────────
  // route.traoptimal[0].summary.{distance, duration}
  // route.traoptimal[0].path [[lng, lat], ...]
  factory DirectionsResponseDto.fromNaverJson(Map<String, dynamic> json) {
    final rawCode = json['code'];
    final code = rawCode is int
        ? rawCode
        : (rawCode != null ? int.tryParse(rawCode.toString()) ?? -1 : -1);
    final message = json['message'] as String? ?? '알 수 없는 오류';

    DirectionsRouteDto? route;
    final routeMap = json['route'] as Map<String, dynamic>?;
    if (routeMap != null) {
      for (final key in ['traoptimal', 'trafast', 'tracomfort']) {
        final list = routeMap[key] as List?;
        if (list != null && list.isNotEmpty) {
          final r = list[0] as Map<String, dynamic>;
          final s = r['summary'] as Map<String, dynamic>;
          final pathList = r['path'] as List;
          final coords = pathList.map((p) {
            final pt = p as List;
            return CoordinateDto(
              latitude: (pt[1] as num).toDouble(),
              longitude: (pt[0] as num).toDouble(),
            );
          }).toList();
          route = DirectionsRouteDto(
            summary: DirectionsSummaryDto(
              distance: (s['distance'] as num).toInt(),
              duration: (s['duration'] as num).toInt(),
            ),
            path: coords,
          );
          break;
        }
      }
    }

    return DirectionsResponseDto(code: code, message: message, route: route);
  }

  // ── OSRM 응답 파싱 (보행자 도보) ──────────────────────────────────────────
  // routes[0].geometry.coordinates [[lng, lat], ...]
  // routes[0].distance (미터), routes[0].duration (초)
  factory DirectionsResponseDto.fromOsrmJson(Map<String, dynamic> json) {
    final code = json['code'] as String? ?? '';
    if (code != 'Ok') {
      return DirectionsResponseDto(
          code: -1, message: json['message'] as String? ?? '경로 없음');
    }

    final routes = json['routes'] as List?;
    if (routes == null || routes.isEmpty) {
      return const DirectionsResponseDto(code: -1, message: '경로 없음');
    }

    final r = routes[0] as Map<String, dynamic>;
    final distanceM = (r['distance'] as num).toInt();
    final durationSec = (r['duration'] as num).toInt();

    final geometry = r['geometry'] as Map<String, dynamic>;
    final coordinates = geometry['coordinates'] as List;
    final path = coordinates.map((c) {
      final pt = c as List;
      return CoordinateDto(
        latitude: (pt[1] as num).toDouble(),
        longitude: (pt[0] as num).toDouble(),
      );
    }).toList();

    return DirectionsResponseDto(
      code: 0,
      message: 'Ok',
      route: DirectionsRouteDto(
        summary: DirectionsSummaryDto(
          distance: distanceM,
          duration: durationSec * 1000, // 초 → 밀리초
        ),
        path: path,
      ),
    );
  }
}
