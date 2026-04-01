import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:whitecane/domain/model/place.dart';
import 'package:whitecane/presentation/common/map_component.dart';

class PlaceItem extends StatelessWidget {
  final Place place;
  final GlobalKey<MapComponentState> mapComponentKey;

  const PlaceItem({
    super.key,
    required this.place,
    required this.mapComponentKey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1.0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        place.placeName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        place.category,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4.0),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 18, color: Colors.red),
                      const SizedBox(width: 4.0),
                      Flexible(
                        child: Text(
                          place.address,
                          style: const TextStyle(
                              fontSize: 14, color: Colors.black),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 18, color: Colors.blue),
                      const SizedBox(width: 4.0),
                      Text(
                        place.contact,
                        style:
                            const TextStyle(fontSize: 14, color: Colors.blue),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 20),
              onPressed: () {
                Get.back();
                mapComponentKey.currentState?.focusOnPlace(place);
              },
            ),
          ],
        ),
      ),
    );
  }
}
