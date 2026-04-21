import 'package:whitecane/domain/model/entrance.dart';

class Place {
  final String placeName;
  final String address;
  final String category;
  final String contact;
  final double latitude;
  final double longitude;
  final List<Entrance> entrances;

  const Place({
    required this.placeName,
    required this.address,
    required this.category,
    required this.contact,
    required this.latitude,
    required this.longitude,
    this.entrances = const [],
  });
}
