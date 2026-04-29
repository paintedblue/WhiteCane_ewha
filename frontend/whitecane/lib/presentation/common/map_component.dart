import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:whitecane/data/local/mock_building_data.dart';
import 'package:whitecane/data/remote/api/naver_directions_api.dart';
export 'package:whitecane/data/remote/api/naver_directions_api.dart' show TransportMode;
import 'package:whitecane/data/remote/api/navigation_api.dart';
import 'package:whitecane/data/remote/dto/navigation_dto.dart';
import 'package:whitecane/domain/model/indoor_room.dart';
import 'package:whitecane/domain/model/place.dart';
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

  // ── 내비게이션 상태 ────────────────────────────────────────────────────────
  bool _isNavigating = false;
  List<CoordinateDto> _navPath = [];
  CoordinateDto? _navDestination;
  int _navTotalDistance = 0;
  int _navTotalDuration = 0;
  int _navRemainingDistance = 0;
  int _navRemainingDuration = 0;
  Place? _navPlace;
  IndoorRoom? _navSelectedRoom;

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

    _locationSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((position) {
      _currentPosition = position;
      if (_isNavigating) _updateNavProgress(position);
      if (_isFollowingUser) _moveCameraTo(position);
    });
  }

  void _moveCameraTo(Position position) {
    final target = NLatLng(position.latitude, position.longitude);
    if (_isNavigating) {
      _mapController?.updateCamera(
        NCameraUpdate.fromCameraPosition(NCameraPosition(
          target: target,
          zoom: 18,
          bearing: position.heading >= 0 ? position.heading : 0,
          tilt: 45,
        )),
      );
    } else {
      _mapController?.updateCamera(
        NCameraUpdate.scrollAndZoomTo(target: target),
      );
    }
  }

  void _resumeFollowing() {
    setState(() => _isFollowingUser = true);
    if (_currentPosition != null) _moveCameraTo(_currentPosition!);
  }

  void resumeFollowing() {
    setState(() => _isFollowingUser = true);
  }

  // ── 테스트용: 현재 위치를 임의 좌표로 강제 설정 ───────────────────────────
  void debugSetPosition(double lat, double lng) {
    final fakePos = Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
      accuracy: 5.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );
    _currentPosition = fakePos;
    if (_isNavigating) _updateNavProgress(fakePos);
    if (_isFollowingUser) _moveCameraTo(fakePos);
  }

  Future<void> focusOnPlace(Place place) async {
    setState(() => _isFollowingUser = false);
    try {
      final latLng = NLatLng(place.latitude, place.longitude);

      if (_hasDestinationMarker) {
        try {
          await _mapController?.deleteOverlay(
              NOverlayInfo(type: NOverlayType.marker, id: _destinationMarkerId));
        } catch (_) {}
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

  Future<void> clearMarkers() async {
    await _mapController?.clearOverlays();
    _hasDestinationMarker = false;
  }

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

  // ── 내비게이션 시작/종료/업데이트 ──────────────────────────────────────────

  void startNavigation(List<CoordinateDto> path, CoordinateDto destination,
      int totalDistance, int totalDuration, Place place, IndoorRoom? selectedRoom) {
    if (!mounted) return;

    // 이미 목적지에 있으면 실외 안내 없이 즉시 도착 처리
    if (_currentPosition != null) {
      final dist = Geolocator.distanceBetween(
        _currentPosition!.latitude, _currentPosition!.longitude,
        destination.latitude, destination.longitude,
      );
      if (dist < 25) {
        _navPlace = place;
        _navSelectedRoom = selectedRoom;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _onArrived();
        });
        return;
      }
    }

    setState(() {
      _isNavigating = true;
      _navPath = List.from(path);
      _navDestination = destination;
      _navTotalDistance = totalDistance;
      _navTotalDuration = totalDuration;
      _navRemainingDistance = totalDistance;
      _navRemainingDuration = totalDuration;
      _navPlace = place;
      _navSelectedRoom = selectedRoom;
      _isFollowingUser = true;
    });
    if (_currentPosition != null) _moveCameraTo(_currentPosition!);
  }

  Future<void> _stopNavigation() async {
    if (!mounted) return;
    setState(() {
      _isNavigating = false;
      _navPath = [];
      _navDestination = null;
      _navPlace = null;
      _navSelectedRoom = null;
    });
    try {
      await _mapController?.deleteOverlay(
          NOverlayInfo(type: NOverlayType.polylineOverlay, id: _routeOverlayId));
    } catch (_) {}
    if (_currentPosition != null) {
      _mapController?.updateCamera(
        NCameraUpdate.fromCameraPosition(NCameraPosition(
          target: NLatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          zoom: 16,
          bearing: 0,
          tilt: 0,
        )),
      );
    }
  }

  void _updateNavProgress(Position position) {
    if (_navPath.length < 2 || _navDestination == null) return;

    final distToDest = Geolocator.distanceBetween(
      position.latitude, position.longitude,
      _navDestination!.latitude, _navDestination!.longitude,
    );
    if (distToDest < 25) {
      _onArrived();
      return;
    }

    int closestIdx = 0;
    double minDist = double.infinity;
    for (int i = 0; i < _navPath.length; i++) {
      final d = Geolocator.distanceBetween(
        position.latitude, position.longitude,
        _navPath[i].latitude, _navPath[i].longitude,
      );
      if (d < minDist) {
        minDist = d;
        closestIdx = i;
      }
    }

    double remaining = 0;
    for (int i = closestIdx; i < _navPath.length - 1; i++) {
      remaining += Geolocator.distanceBetween(
        _navPath[i].latitude, _navPath[i].longitude,
        _navPath[i + 1].latitude, _navPath[i + 1].longitude,
      );
    }

    if (closestIdx > 0) _updateRoutePolyline(_navPath.sublist(closestIdx));

    if (!mounted) return;
    setState(() {
      _navRemainingDistance = remaining.toInt();
      _navRemainingDuration = _navTotalDistance > 0
          ? (_navTotalDuration * remaining / _navTotalDistance).toInt()
          : 0;
    });
  }

  Future<void> _updateRoutePolyline(List<CoordinateDto> remaining) async {
    if (remaining.length < 2) return;
    try {
      await _mapController?.deleteOverlay(
          NOverlayInfo(type: NOverlayType.polylineOverlay, id: _routeOverlayId));
      final coords =
          remaining.map((c) => NLatLng(c.latitude, c.longitude)).toList();
      await _mapController?.addOverlay(NPolylineOverlay(
        id: _routeOverlayId,
        coords: coords,
        color: const Color(0xFF3478F6),
        width: 5,
      ));
    } catch (_) {}
  }

  void _onArrived() {
    final place = _navPlace;
    final room = _navSelectedRoom;
    _stopNavigation();
    if (!mounted) return;

    final hasIndoor = place != null &&
        MockBuildingData.getRoomsForPlace(place.placeName).isNotEmpty;

    if (hasIndoor) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => _IndoorTransitionSheet(
          place: place,
          selectedRoom: room,
          onStartIndoor: () {
            IndoorNavigationSheet.showSheet(
              context,
              buildingName: place.placeName,
              destinationRoom: room,
            );
          },
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('도착'),
          content: const Text('목적지에 도착했습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }
  }

  void _showPlaceDetailSheet(Place place) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => _PlaceDetailSheet(
        place: place,
        directionsApi: widget.directionsApi,
        getCurrentPosition: () async {
          if (_currentPosition != null) return _getCurrentCoordinate();
          try {
            final pos = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                  accuracy: LocationAccuracy.high),
            );
            _currentPosition = pos;
            return _getCurrentCoordinate();
          } catch (_) {
            return null;
          }
        },
        onGetCoordinate: (nodeId) async {
          try {
            return await widget.navigationApi.getNodeCoordinates(nodeId);
          } catch (_) {
            return null;
          }
        },
        onRouteDrawn: (route, destination, totalDistance, totalDuration, place, room) {
          drawRoute(route, destination);
          startNavigation(route, destination, totalDistance, totalDuration, place, room);
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
    return Stack(
      children: [
        NaverMap(
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
            if (reason == NCameraUpdateReason.gesture) {
              if (_isFollowingUser) setState(() => _isFollowingUser = false);
            }
          },
        ),
        if (_isNavigating)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _NavigationHud(
              remainingDistance: _navRemainingDistance,
              remainingDuration: _navRemainingDuration,
              destinationName: _navPlace?.placeName ?? '목적지',
              onStop: _stopNavigation,
            ),
          ),
        // ── 내 위치로 재중심 버튼 ─────────────────────────────────────────
        if (_isNavigating && !_isFollowingUser)
          Positioned(
            bottom: 110,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'recenter',
              onPressed: _resumeFollowing,
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF3478F6),
              elevation: 4,
              child: const Icon(Icons.navigation),
            ),
          ),
      ],
    );
  }
}

// ── 장소 상세 바텀시트 ────────────────────────────────────────────────────────

class _PlaceDetailSheet extends StatefulWidget {
  final Place place;
  final NaverDirectionsApi directionsApi;
  final Future<CoordinateDto?> Function() getCurrentPosition;
  final Future<CoordinateDto?> Function(String nodeId) onGetCoordinate;
  final void Function(List<CoordinateDto> route, CoordinateDto destination,
      int totalDistance, int totalDuration, Place place, IndoorRoom? selectedRoom) onRouteDrawn;

  const _PlaceDetailSheet({
    required this.place,
    required this.directionsApi,
    required this.getCurrentPosition,
    required this.onGetCoordinate,
    required this.onRouteDrawn,
  });

  @override
  State<_PlaceDetailSheet> createState() => _PlaceDetailSheetState();
}

class _PlaceDetailSheetState extends State<_PlaceDetailSheet> {
  IndoorRoom? _selectedRoom;
  bool _isSearching = false;
  bool _isNavigating = false;
  TransportMode _transportMode = TransportMode.walking;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  List<IndoorRoom> get _availableRooms =>
      MockBuildingData.getRoomsForPlace(widget.place.placeName);

  bool get _hasIndoorData => _availableRooms.isNotEmpty;

  List<IndoorRoom> get _filteredRooms =>
      MockBuildingData.filterRooms(_availableRooms, _searchQuery);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _startSearch() => setState(() => _isSearching = true);

  void _selectRoom(IndoorRoom room) => setState(() {
        _selectedRoom = room;
        _isSearching = false;
        _searchController.clear();
        _searchQuery = '';
      });

  void _clearRoom() => setState(() {
        _selectedRoom = null;
        _isSearching = false;
        _searchController.clear();
        _searchQuery = '';
      });

  Future<void> _startRoute() async {
    setState(() => _isNavigating = true);
    try {
      final currentPos = await widget.getCurrentPosition();
      debugPrint('[_startRoute] currentPos=$currentPos');
      if (currentPos == null) {
        _showError('현재 위치를 가져올 수 없습니다.');
        return;
      }

      final destination = CoordinateDto(
        latitude: widget.place.latitude,
        longitude: widget.place.longitude,
      );

      final result = await widget.directionsApi.getRoute(
        startLat: currentPos.latitude,
        startLng: currentPos.longitude,
        goalLat: destination.latitude,
        goalLng: destination.longitude,
        mode: _transportMode,
      );
      debugPrint('[_startRoute] result code=${result.code} route=${result.route}');

      if (!mounted) return;

      if (result.code != 0 || result.route == null) {
        _showError(_routeErrorMessage(result.code));
        return;
      }

      final summary = result.route!.summary;
      widget.onRouteDrawn(
          result.route!.path, destination, summary.distance, summary.duration,
          widget.place, _selectedRoom);
    } catch (e, st) {
      debugPrint('[_startRoute] ERROR: $e\n$st');
      _showError('경로를 불러오지 못했습니다. 잠시 후 다시 시도해주세요.');
    } finally {
      if (mounted) setState(() => _isNavigating = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('안내'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  String _routeErrorMessage(int code) {
    switch (code) {
      case 1: return '출발지와 목적지가 너무 가깝습니다.';
      case 2: return '해당 경로를 찾을 수 없습니다.';
      case 3: return '위치 좌표에 오류가 있습니다.';
      case 401: return 'Naver 자동차 경로 API 권한이 없습니다.\nNaver Cloud Platform 콘솔에서\n길찾기(Directions 5) 서비스를 활성화해 주세요.';
      default: return '경로를 찾을 수 없습니다. (코드: $code)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // ── 헤더 ────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.place.placeName,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(widget.place.category,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.grey)),
                      if (widget.place.address.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 14, color: Colors.red),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(widget.place.address,
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // ── 이동 수단 선택 ────────────────────────────────────
            _TransportModeSelector(
              selected: _transportMode,
              onChanged: (m) => setState(() => _transportMode = m),
            ),

            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // ── 경로 흐름 시각화 ──────────────────────────────────
            _RouteFlowWidget(place: widget.place, room: _selectedRoom),

            // ── 실내 목적지 검색 영역 ─────────────────────────────
            if (_hasIndoorData) ...[
              const SizedBox(height: 16),
              _IndoorSearchSection(
                isSearching: _isSearching,
                selectedRoom: _selectedRoom,
                searchController: _searchController,
                filteredRooms: _filteredRooms,
                onStartSearch: _startSearch,
                onQueryChanged: (q) => setState(() => _searchQuery = q),
                onRoomSelected: _selectRoom,
                onClear: _clearRoom,
              ),
            ],

            const SizedBox(height: 20),

            // ── 경로 안내하기 버튼 ────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isNavigating ? null : _startRoute,
                icon: _isNavigating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.navigation, color: Colors.white, size: 20),
                label: const Text(
                  '경로 안내하기',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kButtonColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
          ),       // Column
        ),         // SingleChildScrollView
      ),           // Container
    );             // Padding
  }
}

// ── 이동 수단 선택 위젯 ───────────────────────────────────────────────────────

class _TransportModeSelector extends StatelessWidget {
  final TransportMode selected;
  final ValueChanged<TransportMode> onChanged;

  const _TransportModeSelector({
    required this.selected,
    required this.onChanged,
  });

  static const _modes = [
    (TransportMode.walking, Icons.directions_walk, '도보'),
    (TransportMode.car, Icons.directions_car, '자동차'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _modes.map((entry) {
        final (mode, icon, label) = entry;
        final isSelected = selected == mode;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            avatar: Icon(icon,
                size: 16,
                color: isSelected ? Colors.white : Colors.black54),
            label: Text(label,
                style: TextStyle(
                  fontSize: 13,
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                )),
            selected: isSelected,
            selectedColor: kButtonColor,
            backgroundColor: Colors.grey.shade100,
            side: BorderSide(
                color: isSelected ? kButtonColor : Colors.grey.shade300),
            onSelected: (_) => onChanged(mode),
          ),
        );
      }).toList(),
    );
  }
}

// ── 실내 목적지 검색 섹션 ─────────────────────────────────────────────────────

class _IndoorSearchSection extends StatelessWidget {
  final bool isSearching;
  final IndoorRoom? selectedRoom;
  final TextEditingController searchController;
  final List<IndoorRoom> filteredRooms;
  final VoidCallback onStartSearch;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<IndoorRoom> onRoomSelected;
  final VoidCallback onClear;

  const _IndoorSearchSection({
    required this.isSearching,
    required this.selectedRoom,
    required this.searchController,
    required this.filteredRooms,
    required this.onStartSearch,
    required this.onQueryChanged,
    required this.onRoomSelected,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    // 방이 선택된 상태
    if (selectedRoom != null) {
      return _SelectedRoomChip(room: selectedRoom!, onClear: onClear);
    }

    // 검색 중인 상태
    if (isSearching) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 검색 필드
          TextField(
            controller: searchController,
            autofocus: true,
            onChanged: onQueryChanged,
            decoration: InputDecoration(
              hintText: '강의실 번호 검색 (예: B131)',
              hintStyle:
                  TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onClear,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: kButtonColor),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 검색 결과 목록
          if (filteredRooms.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('검색 결과가 없습니다.',
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade500)),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: filteredRooms.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: Colors.grey.shade100),
                itemBuilder: (_, i) {
                  final room = filteredRooms[i];
                  return ListTile(
                    dense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    leading: const Icon(Icons.maps_home_work,
                        size: 18, color: Color(0xFF5856D6)),
                    title: Text(room.displayName,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    onTap: () => onRoomSelected(room),
                  );
                },
              ),
            ),
        ],
      );
    }

    // 기본 상태: "실내 목적지 추가" 버튼
    return OutlinedButton.icon(
      onPressed: onStartSearch,
      icon: const Icon(Icons.add, size: 18, color: Color(0xFF5856D6)),
      label: const Text(
        '실내 목적지 추가',
        style: TextStyle(
            fontSize: 14,
            color: Color(0xFF5856D6),
            fontWeight: FontWeight.w500),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFF5856D6), width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    );
  }
}

class _SelectedRoomChip extends StatelessWidget {
  final IndoorRoom room;
  final VoidCallback onClear;

  const _SelectedRoomChip({required this.room, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF5856D6).withAlpha(15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: const Color(0xFF5856D6).withAlpha(80), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.maps_home_work,
              size: 16, color: Color(0xFF5856D6)),
          const SizedBox(width: 6),
          Text(
            '실내 목적지: ${room.displayName}',
            style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF5856D6),
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onClear,
            child: Icon(Icons.cancel,
                size: 16, color: const Color(0xFF5856D6).withAlpha(160)),
          ),
        ],
      ),
    );
  }
}

// ── 경로 흐름 위젯 ────────────────────────────────────────────────────────────

class _RouteFlowWidget extends StatelessWidget {
  final Place place;
  final IndoorRoom? room;

  const _RouteFlowWidget({required this.place, required this.room});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 내 위치
        _FlowStep(
          dot: _Dot(color: const Color(0xFF34C759), icon: Icons.my_location),
          label: '내 위치',
          labelStyle: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        // 실외 구간 연결선
        _FlowConnector(label: '실외 도보'),
        // 건물 (실외 목적지)
        _FlowStep(
          dot: _Dot(color: kButtonColor, icon: Icons.location_on),
          label: place.placeName,
          labelStyle: const TextStyle(
              fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
          sublabel: place.address.isNotEmpty ? place.address : null,
        ),
        // 실내 구간 (indoorRoom 있을 때만)
        if (room != null) ...[
          _FlowConnector(label: '실내 이동', isIndoor: true),
          _FlowStep(
            dot: _Dot(color: const Color(0xFF5856D6), icon: Icons.maps_home_work),
            label: room!.displayName,
            labelStyle: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5856D6)),
            sublabel: '${place.placeName} 내부',
          ),
        ],
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final IconData icon;

  const _Dot({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}

class _FlowStep extends StatelessWidget {
  final Widget dot;
  final String label;
  final TextStyle labelStyle;
  final String? sublabel;

  const _FlowStep({
    required this.dot,
    required this.label,
    required this.labelStyle,
    this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        dot,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: labelStyle),
              if (sublabel != null)
                Text(sublabel!,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500),
                    overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

// ── 내비게이션 HUD ─────────────────────────────────────────────────────────────

class _NavigationHud extends StatelessWidget {
  final int remainingDistance;
  final int remainingDuration;
  final String destinationName;
  final VoidCallback onStop;

  const _NavigationHud({
    required this.remainingDistance,
    required this.remainingDuration,
    required this.destinationName,
    required this.onStop,
  });

  String _formatDistance(int meters) {
    if (meters < 1000) return '${meters}m';
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }

  String _formatDuration(int ms) {
    final minutes = ms ~/ 60000;
    if (minutes < 60) return '$minutes분';
    return '${minutes ~/ 60}시간 ${minutes % 60}분';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, 16 + MediaQuery.of(context).padding.bottom),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF3478F6).withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.navigation,
                color: Color(0xFF3478F6), size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$destinationName까지',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatDistance(remainingDistance),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '약 ${_formatDuration(remainingDuration)} 남음',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onStop,
            style: TextButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('안내 종료',
                style:
                    TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _FlowConnector extends StatelessWidget {
  final String label;
  final bool isIndoor;

  const _FlowConnector({required this.label, this.isIndoor = false});

  @override
  Widget build(BuildContext context) {
    final color = isIndoor ? const Color(0xFF5856D6) : kButtonColor;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // 세로선 (점 중앙 정렬: 점 width 36, 선 width 2 → 좌측 패딩 17)
          SizedBox(
            width: 36,
            child: Center(
              child: Container(
                width: 2,
                height: 28,
                color: color.withAlpha(80),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withAlpha(60)),
            ),
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 실내 안내 전환 시트 ────────────────────────────────────────────────────────

class _IndoorTransitionSheet extends StatelessWidget {
  final Place place;
  final IndoorRoom? selectedRoom;
  final VoidCallback onStartIndoor;

  const _IndoorTransitionSheet({
    required this.place,
    required this.selectedRoom,
    required this.onStartIndoor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 28, 24, 24 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 도착 아이콘
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF34C759).withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: Color(0xFF34C759), size: 36),
          ),
          const SizedBox(height: 14),
          const Text(
            '목적지 도착!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            place.placeName,
            style: const TextStyle(fontSize: 15, color: Colors.grey),
          ),
          if (selectedRoom != null) ...[
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF5856D6).withAlpha(18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFF5856D6).withAlpha(60)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.maps_home_work,
                      size: 15, color: Color(0xFF5856D6)),
                  const SizedBox(width: 6),
                  Text(
                    '실내 목적지: ${selectedRoom!.displayName}',
                    style: const TextStyle(
                        color: Color(0xFF5856D6),
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),
          // 실내 안내 시작 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onStartIndoor();
              },
              icon: const Icon(Icons.map_outlined,
                  color: Colors.white, size: 20),
              label: const Text(
                '실내 안내 시작',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5856D6),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // 안내 종료 버튼
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                '안내 종료',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

