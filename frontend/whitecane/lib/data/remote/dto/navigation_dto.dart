/// 좌표 DTO
class CoordinateDto {
  final double latitude;
  final double longitude;

  const CoordinateDto({required this.latitude, required this.longitude});

  factory CoordinateDto.fromJson(Map<String, dynamic> json) => CoordinateDto(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
      };
}

/// 휠체어 버전
enum WheelchairVersion {
  standardWheelchair,
  basicPowerWheelchair,
  advancedPowerWheelchair,
}

extension WheelchairVersionExt on WheelchairVersion {
  String toJsonValue() {
    switch (this) {
      case WheelchairVersion.standardWheelchair:
        return 'standard_wheelchair';
      case WheelchairVersion.basicPowerWheelchair:
        return 'basic_power_wheelchair';
      case WheelchairVersion.advancedPowerWheelchair:
        return 'advanced_power_wheelchair';
    }
  }
}

/// 경로 요청 DTO
class RouteRequestDto {
  final CoordinateDto start;
  final CoordinateDto end;
  final WheelchairVersion wheelchairVersion;

  const RouteRequestDto({
    required this.start,
    required this.end,
    required this.wheelchairVersion,
  });

  Map<String, dynamic> toJson() => {
        'start': start.toJson(),
        'end': end.toJson(),
        'wheelchair_version': wheelchairVersion.toJsonValue(),
      };
}

/// 경로 응답 DTO
class RouteResponseDto {
  final String duration;
  final String distance;
  final List<CoordinateDto> route;
  final List<String> warnings;

  const RouteResponseDto({
    required this.duration,
    required this.distance,
    required this.route,
    required this.warnings,
  });

  factory RouteResponseDto.fromJson(Map<String, dynamic> json) =>
      RouteResponseDto(
        duration: json['duration'] as String,
        distance: json['distance'] as String,
        route: (json['route'] as List)
            .map((e) => CoordinateDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        warnings: (json['warnings'] as List).cast<String>(),
      );
}
