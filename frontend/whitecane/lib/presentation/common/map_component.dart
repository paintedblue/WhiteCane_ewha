import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:whitecane/data/remote/api/navigation_api.dart';
import 'package:whitecane/data/remote/dto/navigation_dto.dart';
import 'package:whitecane/domain/model/place.dart';
import 'package:whitecane/presentation/common/route_finder_modal.dart';

/// 지도 컴포넌트
///
/// TODO: 지도 API 연동 시 이 컴포넌트 내부의 _MapPlaceholder를 실제 지도 위젯으로 교체하세요.
/// 현재 위치 버튼, 마커 관리, 경로 표시 등의 메서드 시그니처는 유지하면서
/// 지도 API에 맞게 구현을 채워넣으면 됩니다.
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
  // 현재 선택된 장소 정보 (마커 표시용)
  Place? _selectedPlace;
  CoordinateDto? _currentLocation;
  List<CoordinateDto> _routeCoordinates = [];
  CoordinateDto? _routeDestination;

  /// 장소 선택 시 지도 포커스 이동 및 마커 표시
  Future<void> focusOnPlace(Place place) async {
    try {
      final coordinate =
          await widget.navigationApi.getNodePolygonCoordinates(place.nodeId);
      setState(() {
        _selectedPlace = place;
        _routeCoordinates = [];
        _routeDestination = null;
      });

      // TODO: 지도 API 연동 시 카메라 이동 구현
      // mapController.animateTo(coordinate.latitude, coordinate.longitude, zoom: 16.0);

      _showPlaceDetailSheet(place, coordinate);
    } catch (e) {
      debugPrint('장소 포커스 실패: $e');
    }
  }

  /// 마커 추가
  void addMarkers(List<dynamic> items, String category) {
    // TODO: 지도 API 연동 시 마커 표시 구현
    setState(() {});
  }

  /// 마커 초기화
  void clearMarkers() {
    setState(() {
      _selectedPlace = null;
    });
    // TODO: 지도 API 연동 시 마커 제거 구현
  }

  /// 경로 지도에 그리기
  void drawRoute(List<CoordinateDto> route, CoordinateDto destination) {
    setState(() {
      _routeCoordinates = route;
      _routeDestination = destination;
    });
    // TODO: 지도 API 연동 시 경로 폴리라인 그리기 구현
  }

  /// 현재 위치로 이동
  Future<void> _moveToCurrentLocation() async {
    var status = await Permission.location.request();
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return;
    }
    if (!status.isGranted) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLocation = CoordinateDto(
          latitude: position.latitude,
          longitude: position.longitude,
        );
      });

      // TODO: 지도 API 연동 시 카메라 이동 구현
      // mapController.animateTo(position.latitude, position.longitude, zoom: 16.0);
    } catch (e) {
      debugPrint('위치 가져오기 실패: $e');
    }
  }

  void _showPlaceDetailSheet(Place place, CoordinateDto coordinate) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _PlaceDetailSheet(
        place: place,
        coordinate: coordinate,
        onNavigate: () {
          Navigator.pop(context);
          RouteFinderModal.showModal(
            context,
            destinationName: place.placeName,
            destinationNodeId: place.nodeId,
            ramps: const [],
            onGetCoordinate: (nodeId) =>
                widget.navigationApi.getNodeCoordinates(nodeId),
            onRouteDraw: (route, destination) {
              drawRoute(route, destination);
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ─── 지도 영역 ───────────────────────────────────────────
        // TODO: 아래 _MapPlaceholder를 실제 지도 위젯으로 교체하세요.
        // 예시:
        //   FlutterMap(options: ..., layers: [...])
        //   GoogleMap(initialCameraPosition: ..., ...)
        //   MapboxMap(...)
        _MapPlaceholder(
          currentLocation: _currentLocation,
          routeCoordinates: _routeCoordinates,
          routeDestination: _routeDestination,
          selectedPlace: _selectedPlace,
        ),

        // ─── 현재 위치 버튼 (우측 하단) ──────────────────────────
        Positioned(
          bottom: 10,
          right: 10,
          child: FloatingActionButton.small(
            onPressed: _moveToCurrentLocation,
            backgroundColor: const Color.fromRGBO(136, 181, 197, 1),
            child: const Icon(Icons.my_location, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

/// 지도 API 연동 전 사용되는 플레이스홀더 위젯
class _MapPlaceholder extends StatelessWidget {
  final CoordinateDto? currentLocation;
  final List<CoordinateDto> routeCoordinates;
  final CoordinateDto? routeDestination;
  final Place? selectedPlace;

  const _MapPlaceholder({
    this.currentLocation,
    required this.routeCoordinates,
    this.routeDestination,
    this.selectedPlace,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE8EAF6),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              '지도 API 연동 필요',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'map_component.dart 내\nTODO 주석을 참고하여 연동하세요.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
            if (currentLocation != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Column(
                  children: [
                    const Text('현재 위치',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      'lat: ${currentLocation!.latitude.toStringAsFixed(5)}\nlon: ${currentLocation!.longitude.toStringAsFixed(5)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
            if (selectedPlace != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Column(
                  children: [
                    const Text('선택된 목적지',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      selectedPlace!.placeName,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
            if (routeCoordinates.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '경로 좌표 ${routeCoordinates.length}개 수신됨',
                  style: const TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 장소 상세 바텀시트
class _PlaceDetailSheet extends StatelessWidget {
  final Place place;
  final CoordinateDto coordinate;
  final VoidCallback onNavigate;

  const _PlaceDetailSheet({
    required this.place,
    required this.coordinate,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
                      style:
                          const TextStyle(fontSize: 14, color: Colors.grey),
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
          const SizedBox(height: 12),
          if (place.alias.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.location_on, size: 18, color: Colors.red),
                const SizedBox(width: 4),
                Expanded(
                    child: Text(place.alias,
                        style: const TextStyle(fontSize: 14))),
              ],
            ),
          if (place.contact.isNotEmpty && place.contact != '없음') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone, size: 18, color: Colors.blue),
                const SizedBox(width: 4),
                Text(place.contact,
                    style:
                        const TextStyle(fontSize: 14, color: Colors.blue)),
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
                backgroundColor: const Color(0xff3478F6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
