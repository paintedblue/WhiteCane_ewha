import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:whitecane/data/remote/api/naver_directions_api.dart';
import 'package:whitecane/data/remote/api/navigation_api.dart';
import 'package:whitecane/data/remote/dto/navigation_dto.dart';
import 'package:whitecane/domain/model/place.dart';
import 'package:whitecane/presentation/common/route_finder_modal.dart';
import 'package:whitecane/presentation/indoor/indoor_navigation_sheet.dart';
import 'package:whitecane/presentation/theme/color.dart';

class MapComponent extends StatefulWidget {
  final NavigationApi navigationApi;
  final NaverDirectionsApi directionsApi;
  final String baseUrl;

  const MapComponent({
    super.key,
    required this.navigationApi,
    required this.directionsApi,
    required this.baseUrl,
  });

  @override
  State<MapComponent> createState() => MapComponentState();
}

class MapComponentState extends State<MapComponent> {
  NaverMapController? _mapController;
  bool _hasDestinationMarker = false;
  StreamSubscription<Position>? _locationSub;
  bool _isFollowingUser = true;
  Position? _currentPosition;

  static const _routeOverlayId = 'route';
  static const _destinationMarkerId = 'destination';

  void _onMapReady(NaverMapController controller) {
    _mapController = controller;
    _startLocationTracking();
  }

  Future<void> _startLocationTracking() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    // 현재 위치로 즉시 카메라 이동
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      _currentPosition = position;
      _moveCameraTo(position);
    } catch (e) {
      debugPrint('현재 위치 조회 실패: $e');
    }

    // 위치 스트림 구독 (5m 이상 이동마다 업데이트)
    _locationSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((position) {
      _currentPosition = position;
      if (_isFollowingUser) _moveCameraTo(position);
    });
  }

  void _moveCameraTo(Position position) {
    _mapController?.updateCamera(
      NCameraUpdate.scrollAndZoomTo(
        target: NLatLng(position.latitude, position.longitude),
      ),
    );
  }

  /// 팔로우 모드 재활성화 (외부에서 호출 가능)
  void resumeFollowing() {
    setState(() => _isFollowingUser = true);
  }

  /// 검색 결과에서 장소 선택 시 지도 포커스 및 상세 시트 표시
  Future<void> focusOnPlace(Place place) async {
    setState(() => _isFollowingUser = false);
    try {
      final latLng = NLatLng(place.latitude, place.longitude);

      if (_hasDestinationMarker) {
        await _mapController?.deleteOverlay(
            NOverlayInfo(type: NOverlayType.marker, id: _destinationMarkerId));
      }
      final marker = NMarker(id: _destinationMarkerId, position: latLng);
      await _mapController?.addOverlay(marker);
      _hasDestinationMarker = true;

      await _mapController?.updateCamera(
        NCameraUpdate.scrollAndZoomTo(target: latLng, zoom: 17)
          ..setAnimation(
              animation: NCameraAnimation.easing,
              duration: const Duration(milliseconds: 500)),
      );

      if (mounted) _showPlaceDetailSheet(place);
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
    _hasDestinationMarker = false;
  }

  /// 경로 폴리라인 그리기
  Future<void> drawRoute(
      List<CoordinateDto> route, CoordinateDto destination) async {
    try {
      await _mapController?.deleteOverlay(
          NOverlayInfo(type: NOverlayType.polylineOverlay, id: _routeOverlayId));
    } catch (_) {}

    if (_hasDestinationMarker) {
      try {
        await _mapController?.deleteOverlay(
            NOverlayInfo(type: NOverlayType.marker, id: _destinationMarkerId));
      } catch (_) {}
    }
    final destMarker = NMarker(
      id: _destinationMarkerId,
      position: NLatLng(destination.latitude, destination.longitude),
    );
    await _mapController?.addOverlay(destMarker);
    _hasDestinationMarker = true;

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

    final bounds = NLatLngBounds.from(coords);
    await _mapController?.updateCamera(
      NCameraUpdate.fitBounds(bounds, padding: const EdgeInsets.all(60)),
    );
  }

  CoordinateDto? _getCurrentCoordinate() {
    if (_currentPosition == null) return null;
    return CoordinateDto(
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
    );
  }

  void _showPlaceDetailSheet(Place place) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => _PlaceDetailSheet(
        place: place,
        directionsApi: widget.directionsApi,
        getCurrentPosition: () async => _getCurrentCoordinate(),
        onGetCoordinate: (nodeId) async {
          try {
            return await widget.navigationApi.getNodeCoordinates(nodeId);
          } catch (_) {
            return null;
          }
        },
        onRouteDrawn: (route, destination) {
          drawRoute(route, destination);
          Navigator.of(sheetContext).pop();
        },
      ),
    );
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NaverMap(
      options: const NaverMapViewOptions(
        initialCameraPosition: NCameraPosition(
          target: NLatLng(37.5620, 126.9469), // 이화여자대학교
          zoom: 16,
        ),
        locationButtonEnable: true,
        consumeSymbolTapEvents: false,
        scaleBarEnable: true,
        compassEnable: true,
      ),
      onMapReady: _onMapReady,
      onMapTapped: (_, __) {},
      onCameraChange: (reason, animated) {
        // 사용자가 직접 드래그한 경우 팔로우 OFF
        if (reason == NCameraUpdateReason.gesture) {
          if (_isFollowingUser) setState(() => _isFollowingUser = false);
        }
      },
    );
  }
}

// ── 장소 상세 바텀시트 ────────────────────────────────────────────────────────

class _PlaceDetailSheet extends StatelessWidget {
  final Place place;
  final NaverDirectionsApi directionsApi;
  final Future<CoordinateDto?> Function() getCurrentPosition;
  final Future<CoordinateDto?> Function(String nodeId) onGetCoordinate;
  final void Function(List<CoordinateDto> route, CoordinateDto destination)
      onRouteDrawn;

  const _PlaceDetailSheet({
    required this.place,
    required this.directionsApi,
    required this.getCurrentPosition,
    required this.onGetCoordinate,
    required this.onRouteDrawn,
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
          if (place.address.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 18, color: Colors.red),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(place.address,
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ],
          if (place.contact.isNotEmpty) ...[
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
          const SizedBox(height: 16),
          Row(
            children: [
              // ── 실외 경로 안내 ──────────────────────────────────
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    RouteFinderModal.showModal(
                      context,
                      destinationName: place.placeName,
                      destinationCoordinate: CoordinateDto(
                        latitude: place.latitude,
                        longitude: place.longitude,
                      ),
                      ramps: place.entrances
                          .map((e) => RampInfo(
                                nodeId: e.nodeId,
                                locationDescription: e.description,
                              ))
                          .toList(),
                      directionsApi: directionsApi,
                      getCurrentPosition: getCurrentPosition,
                      onGetCoordinate: onGetCoordinate,
                      onRouteDraw: onRouteDrawn,
                    );
                  },
                  icon: const Icon(Icons.directions, color: Colors.white,
                      size: 18),
                  label: const Text(
                    '실외 경로',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kButtonColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // ── 실내 경로 안내 ──────────────────────────────────
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    IndoorNavigationSheet.showSheet(
                      context,
                      buildingName: place.placeName,
                    );
                  },
                  icon: const Icon(Icons.maps_home_work, color: Colors.white,
                      size: 18),
                  label: const Text(
                    '실내 경로',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5856D6),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
