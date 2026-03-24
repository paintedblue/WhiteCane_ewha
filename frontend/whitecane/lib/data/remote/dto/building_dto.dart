/// 건물 기본 응답 DTO
class BuildingResponseDto {
  final String alias;
  final int buildingId;
  final String name;
  final String nodeId;
  final String category;
  final String? phoneNumber;
  final String address;

  const BuildingResponseDto({
    required this.alias,
    required this.buildingId,
    required this.name,
    required this.nodeId,
    required this.category,
    this.phoneNumber,
    required this.address,
  });

  factory BuildingResponseDto.fromJson(Map<String, dynamic> json) =>
      BuildingResponseDto(
        alias: json['alias'] as String? ?? '',
        buildingId: json['building_id'] as int,
        name: json['name'] as String? ?? '',
        nodeId: json['node_id'] as String? ?? '',
        category: json['category'] as String? ?? '',
        phoneNumber: json['phone_number'] as String?,
        address: json['address'] as String? ?? '',
      );
}

/// 건물 상세 응답 DTO (경사로, 화장실, 엘리베이터 포함)
class BuildingFullResponseDto {
  final BuildingResponseDto building;
  final List<RampDto> ramps;
  final List<RestroomDto> disabledRestrooms;
  final List<ElevatorDto> elevators;

  const BuildingFullResponseDto({
    required this.building,
    required this.ramps,
    required this.disabledRestrooms,
    required this.elevators,
  });

  factory BuildingFullResponseDto.fromJson(Map<String, dynamic> json) =>
      BuildingFullResponseDto(
        building: BuildingResponseDto.fromJson(
            json['building'] as Map<String, dynamic>),
        ramps: (json['ramps'] as List? ?? [])
            .map((e) => RampDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        disabledRestrooms: (json['disabled_restrooms'] as List? ?? [])
            .map((e) => RestroomDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        elevators: (json['elevators'] as List? ?? [])
            .map((e) => ElevatorDto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class RampDto {
  final int rampId;
  final int buildingId;
  final String nodeId;
  final int floor;
  final String locationDescription;

  const RampDto({
    required this.rampId,
    required this.buildingId,
    required this.nodeId,
    required this.floor,
    required this.locationDescription,
  });

  factory RampDto.fromJson(Map<String, dynamic> json) => RampDto(
        rampId: json['ramp_id'] as int? ?? -1,
        buildingId: json['building_id'] as int? ?? -1,
        nodeId: json['node_id'] as String? ?? '',
        floor: json['floor'] as int? ?? 0,
        locationDescription: json['location_description'] as String? ?? '',
      );
}

class RestroomDto {
  final int restroomId;
  final int buildingId;
  final String nodeId;
  final int floor;
  final String locationDescription;

  const RestroomDto({
    required this.restroomId,
    required this.buildingId,
    required this.nodeId,
    required this.floor,
    required this.locationDescription,
  });

  factory RestroomDto.fromJson(Map<String, dynamic> json) => RestroomDto(
        restroomId: json['restroom_id'] as int? ?? -1,
        buildingId: json['building_id'] as int? ?? -1,
        nodeId: json['node_id'] as String? ?? '',
        floor: json['floor'] as int? ?? 0,
        locationDescription: json['location_description'] as String? ?? '',
      );
}

class ElevatorDto {
  final int elevatorId;
  final int buildingId;
  final String nodeId;
  final String locationDescription;

  const ElevatorDto({
    required this.elevatorId,
    required this.buildingId,
    required this.nodeId,
    required this.locationDescription,
  });

  factory ElevatorDto.fromJson(Map<String, dynamic> json) => ElevatorDto(
        elevatorId: json['elevator_id'] as int? ?? -1,
        buildingId: json['building_id'] as int? ?? -1,
        nodeId: json['node_id'] as String? ?? '',
        locationDescription: json['location_description'] as String? ?? '',
      );
}
