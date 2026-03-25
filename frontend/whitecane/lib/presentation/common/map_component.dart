import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:whitecane/data/remote/api/navigation_api.dart';
import 'package:whitecane/data/remote/dto/navigation_dto.dart';
import 'package:whitecane/domain/model/place.dart';
import 'package:whitecane/presentation/common/route_finder_modal.dart';

class MapComponent extends StatefulWidget {
  final NavigationApi navigationApi;
  final String baseUrl;

  const MapComponent({
    super.key,
    required this.navigationApi,
    required this.baseUrl,
  });

  @override
  State<MapComponent> createState() => MapComponentState();
}

class MapComponentState extends State<MapComponent> {
  NaverMapController? _mapController;

  static const _routeOverlayId = 'route';
  static const _destinationMarkerId = 'destination';

  void _onMapReady(NaverMapController controller) {
    _mapController = controller;
  }

  /// 검색 결과에서 장소 선택 시 지도 포커스 및 상세 시트 표시
  Future<void> focusOnPlace(Place place) async {
    try {
      final coord =
          await widget.navigationApi.getNodePolygonCoordinates(place.nodeId);
      final latLng = NLatLng(coord.latitude, coord.longitude);

      // 기존 목적지 마커 제거 후 새 마커 추가
      await _mapController?.deleteOverlay(
          NOverlayInfo(type: NOverlayType.marker, id: _destinationMarkerId));
      final marker = NMarker(id: _destinationMarkerId, position: latLng);
      await _mapController?.addOverlay(marker);

      // 해당 위치로 카메라 이동
      await _mapController?.updateCamera(
        NCameraUpdate.scrollAndZoomTo(target: latLng, zoom: 17)
          ..setAnimation(
              animation: NCameraAnimation.easing,
              duration: const Duration(milliseconds: 500)),
      );

      if (mounted) _showPlaceDetailSheet(place, coord);
    } catch (e) {
      debugPrint('장소 포커스 실패: $e');
    }
  }

  /// 카테고리 마커 일괄 추가
  Future<void> addMarkers(List<dynamic> items, String category) async {
    await _mapController?.clearOverlays(type: NOverlayType.marker);

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      try {
        CoordinateDto coord;
        String label = '';

        if (item is Map && item.containsKey('latitude')) {
          coord = CoordinateDto(
            latitude: item['latitude'] as double,
            longitude: item['longitude'] as double,
          );
          label = item['name'] as String? ?? '';
        } else {
          continue;
        }

        final marker = NMarker(
          id: '$category-$i',
          position: NLatLng(coord.latitude, coord.longitude),
        );
        if (label.isNotEmpty) {
          marker.setCaption(NOverlayCaption(text: label, textSize: 12));
        }
        await _mapController?.addOverlay(marker);
      } catch (e) {
        debugPrint('마커 추가 실패: $e');
      }
    }
  }

  /// 모든 마커/경로 초기화
  Future<void> clearMarkers() async {
    await _mapController?.clearOverlays();
  }

  /// 경로 폴리라인 그리기
  Future<void> drawRoute(
      List<CoordinateDto> route, CoordinateDto destination) async {
    // 기존 경로 레이어 제거
    await _mapController?.deleteOverlay(
        NOverlayInfo(type: NOverlayType.polylineOverlay, id: _routeOverlayId));

    // 목적지 마커
    final destMarker = NMarker(
      id: _destinationMarkerId,
      position: NLatLng(destination.latitude, destination.longitude),
    );
    await _mapController?.addOverlay(destMarker);

    if (route.length < 2) return;

    final coords =
        route.map((c) => NLatLng(c.latitude, c.longitude)).toList();
    final polyline = NPolylineOverlay(
      id: _routeOverlayId,
      coords: coords,
      color: const Color(0xFF3478F6),
      width: 5,
    );
    await _mapController?.addOverlay(polyline);

    // 경로 전체가 보이도록 카메라 맞춤
    final bounds = NLatLngBounds.from(coords);
    await _mapController?.updateCamera(
      NCameraUpdate.fitBounds(bounds, padding: const EdgeInsets.all(60)),
    );
  }

  void _showPlaceDetailSheet(Place place, CoordinateDto coordinate) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _PlaceDetailSheet(
        place: place,
        onNavigate: () {
          Navigator.pop(context);
          RouteFinderModal.showModal(
            context,
            destinationName: place.placeName,
            destinationNodeId: place.nodeId,
            ramps: const [],
            onGetCoordinate: (nodeId) =>
                widget.navigationApi.getNodeCoordinates(nodeId),
            onRouteDraw: (route, destination) =>
                drawRoute(route, destination),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NaverMap(
      options: const NaverMapViewOptions(
        initialCameraPosition: NCameraPosition(
          target: NLatLng(37.5666102, 126.9783881), // 기본: 서울 시청
          zoom: 14,
        ),
        locationButtonEnable: true,
        consumeSymbolTapEvents: false,
        scaleBarEnable: true,
        compassEnable: true,
      ),
      onMapReady: _onMapReady,
      onMapTapped: (_, __) {},
    );
  }
}

// ── 장소 상세 바텀시트 ────────────────────────────────────────────────────────

class _PlaceDetailSheet extends StatelessWidget {
  final Place place;
  final VoidCallback onNavigate;

  const _PlaceDetailSheet({
    required this.place,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.placeName,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      place.category,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          if (place.alias.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 18, color: Colors.red),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(place.alias,
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ],
          if (place.contact.isNotEmpty && place.contact != '없음') ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.phone, size: 18, color: Colors.blue),
                const SizedBox(width: 4),
                Text(place.contact,
                    style: const TextStyle(fontSize: 14, color: Colors.blue)),
              ],
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onNavigate,
              icon: const Icon(Icons.directions, color: Colors.white),
              label: const Text('경로 안내',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3478F6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
