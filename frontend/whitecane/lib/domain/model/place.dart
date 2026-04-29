import 'package:whitecane/domain/model/entrance.dart';
import 'package:whitecane/domain/model/indoor_room.dart';

class Place {
  final String placeName;
  final String address;
  final String category;
  final String contact;
  final double latitude;
  final double longitude;
  final List<Entrance> entrances;
  final IndoorRoom? indoorRoom;

  const Place({
    required this.placeName,
    required this.address,
    required this.category,
    required this.contact,
    required this.latitude,
    required this.longitude,
    this.entrances = const [],
    this.indoorRoom,
  });

  Place copyWith({
    String? placeName,
    String? address,
    String? category,
    String? contact,
    double? latitude,
    double? longitude,
    List<Entrance>? entrances,
    IndoorRoom? indoorRoom,
  }) {
    return Place(
      placeName: placeName ?? this.placeName,
      address: address ?? this.address,
      category: category ?? this.category,
      contact: contact ?? this.contact,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      entrances: entrances ?? this.entrances,
      indoorRoom: indoorRoom ?? this.indoorRoom,
    );
  }
}
