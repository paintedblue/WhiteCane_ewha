class BuildingResponseDto {
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String category;
  final String? phoneNumber;

  const BuildingResponseDto({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.category,
    this.phoneNumber,
  });

  factory BuildingResponseDto.fromJson(Map<String, dynamic> json) =>
      BuildingResponseDto(
        name: json['name'] as String? ?? '',
        address: json['address'] as String? ?? '',
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        category: json['category'] as String? ?? '',
        phoneNumber: json['phone_number'] as String?,
      );
}
