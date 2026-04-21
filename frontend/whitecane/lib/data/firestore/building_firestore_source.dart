import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:whitecane/domain/model/entrance.dart';
import 'package:whitecane/domain/model/place.dart';

class BuildingFirestoreSource {
  final FirebaseFirestore _db;

  BuildingFirestoreSource({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  Future<List<Place>> searchByName(String name) async {
    final lower = name.toLowerCase();

    final snapshot = await _db.collection('buildings').get();

    return snapshot.docs
        .map((doc) => _fromDoc(doc))
        .where((place) => place.placeName.toLowerCase().contains(lower))
        .toList();
  }

  Place _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    final entranceList = (data['entrances'] as List<dynamic>? ?? [])
        .map((e) => Entrance(
              nodeId: e['nodeId'] as String? ?? '',
              description: e['description'] as String? ?? '',
              latitude: (e['latitude'] as num).toDouble(),
              longitude: (e['longitude'] as num).toDouble(),
            ))
        .toList();

    return Place(
      placeName: data['name'] as String? ?? '',
      address: data['address'] as String? ?? '',
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      category: data['category'] as String? ?? '',
      contact: data['phoneNumber'] as String? ?? '',
      entrances: entranceList,
    );
  }
}
