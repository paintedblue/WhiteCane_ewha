import 'package:whitecane/data/remote/dto/navigation_dto.dart';

class DirectionsSummaryDto {
  final int distance; // 미터
  final int duration; // 밀리초

  const DirectionsSummaryDto({
    required this.distance,
    required this.duration,
  });

  factory DirectionsSummaryDto.fromJson(Map<String, dynamic> json) =>
      DirectionsSummaryDto(
        distance: json['distance'] as int,
        duration: json['duration'] as int,
      );
}

class DirectionsRouteDto {
  final DirectionsSummaryDto summary;
  final List<CoordinateDto> path;

  const DirectionsRouteDto({required this.summary, required this.path});

  factory DirectionsRouteDto.fromJson(Map<String, dynamic> json) {
    // path는 [[경도, 위도], ...] 형식
    final pathList = json['path'] as List;
    final coords = pathList.map((point) {
      final p = point as List;
      return CoordinateDto(
        latitude: (p[1] as num).toDouble(),
        longitude: (p[0] as num).toDouble(),
      );
    }).toList();

    return DirectionsRouteDto(
      summary:
          DirectionsSummaryDto.fromJson(json['summary'] as Map<String, dynamic>),
      path: coords,
    );
  }
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

  factory DirectionsResponseDto.fromJson(Map<String, dynamic> json) {
    DirectionsRouteDto? route;
    final routeMap = json['route'] as Map<String, dynamic>?;
    if (routeMap != null) {
      for (final key in [
        'traoptimal',
        'trafast',
        'tracomfort',
        'traavoidtoll',
        'traavoidcaronly',
      ]) {
        if (routeMap.containsKey(key)) {
          final routes = routeMap[key] as List;
          if (routes.isNotEmpty) {
            route = DirectionsRouteDto.fromJson(
                routes[0] as Map<String, dynamic>);
            break;
          }
        }
      }
    }
    return DirectionsResponseDto(
      code: json['code'] as int,
      message: json['message'] as String? ?? '',
      route: route,
    );
  }
}
