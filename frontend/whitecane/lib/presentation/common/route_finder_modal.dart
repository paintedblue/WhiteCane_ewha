import 'package:flutter/material.dart';
import 'package:whitecane/data/remote/api/naver_directions_api.dart';
import 'package:whitecane/data/remote/dto/navigation_dto.dart';
import 'package:whitecane/presentation/theme/color.dart';

/// 경사로/진입로 정보 모델
class RampInfo {
  final String nodeId;
  final String locationDescription;

  const RampInfo({required this.nodeId, required this.locationDescription});
}

class RouteFinderModal extends StatefulWidget {
  final String destinationName;
  final CoordinateDto destinationCoordinate;
  final List<RampInfo> ramps;
  final NaverDirectionsApi directionsApi;
  final Future<CoordinateDto?> Function() getCurrentPosition;
  final Future<CoordinateDto?> Function(String nodeId) onGetCoordinate;
  final void Function(List<CoordinateDto> route, CoordinateDto destination)
      onRouteDraw;

  const RouteFinderModal({
    super.key,
    required this.destinationName,
    required this.destinationCoordinate,
    required this.ramps,
    required this.directionsApi,
    required this.getCurrentPosition,
    required this.onGetCoordinate,
    required this.onRouteDraw,
  });

  static Future<void> showModal(
    BuildContext context, {
    required String destinationName,
    required CoordinateDto destinationCoordinate,
    required List<RampInfo> ramps,
    required NaverDirectionsApi directionsApi,
    required Future<CoordinateDto?> Function() getCurrentPosition,
    required Future<CoordinateDto?> Function(String nodeId) onGetCoordinate,
    required void Function(List<CoordinateDto> route, CoordinateDto destination)
        onRouteDraw,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => RouteFinderModal(
        destinationName: destinationName,
        destinationCoordinate: destinationCoordinate,
        ramps: ramps,
        directionsApi: directionsApi,
        getCurrentPosition: getCurrentPosition,
        onGetCoordinate: onGetCoordinate,
        onRouteDraw: onRouteDraw,
      ),
    );
  }

  @override
  State<RouteFinderModal> createState() => _RouteFinderModalState();
}

class _RouteFinderModalState extends State<RouteFinderModal> {
  String? _selectedRampNodeId;
  bool _isSecondStep = false;
  bool _isLoading = false;

  bool get _hasRamps => widget.ramps.isNotEmpty;

  void _goToNextStep() {
    setState(() => _isSecondStep = true);
  }

  Future<void> _requestRoute() async {
    if (_hasRamps && _selectedRampNodeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('진입 경로를 선택해주세요.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 현재 위치 조회
      final currentPos = await widget.getCurrentPosition();
      if (currentPos == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('현재 위치를 가져올 수 없습니다.')),
          );
        }
        return;
      }

      // 목적지 좌표 결정
      CoordinateDto destination;
      if (_selectedRampNodeId != null) {
        final coord = await widget.onGetCoordinate(_selectedRampNodeId!);
        if (coord == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('진입로 좌표를 가져올 수 없습니다.')),
            );
          }
          return;
        }
        destination = coord;
      } else {
        destination = widget.destinationCoordinate;
      }

      // 네이버 Directions 15 Walking API 호출
      final result = await widget.directionsApi.getRoute(
        startLat: currentPos.latitude,
        startLng: currentPos.longitude,
        goalLat: destination.latitude,
        goalLng: destination.longitude,
      );

      if (result.code != 0 || result.route == null) {
        if (mounted) {
          final msg = _friendlyErrorMessage(result.code, result.message);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
        }
        return;
      }

      widget.onRouteDraw(result.route!.path, destination);

      if (mounted) {
        final summary = result.route!.summary;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '거리: ${_formatDistance(summary.distance)}  ·  '
              '예상 시간: ${_formatDuration(summary.duration)}',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('경로를 불러오지 못했습니다. 잠시 후 다시 시도해주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyErrorMessage(int code, String raw) {
    switch (code) {
      case 1:
        return '출발지와 목적지가 너무 가깝습니다.';
      case 2:
        return '해당 경로를 찾을 수 없습니다.';
      case 3:
        return '위치 좌표에 오류가 있습니다.';
      default:
        return '경로를 찾을 수 없습니다. (코드: $code)';
    }
  }

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
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            if (!_isSecondStep) _buildRouteInputs() else _buildRampSelector(),
            const SizedBox(height: 16),
            _buildActionButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        if (_isSecondStep)
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 24, color: Colors.grey),
            onPressed: () => setState(() => _isSecondStep = false),
          ),
        Expanded(
          child: Text(
            _isSecondStep ? '진입 경로 선택' : '경로 안내',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 24, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildRouteInputs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLocationField(
          icon: Icons.my_location,
          text: '내 위치',
          isActive: false,
        ),
        const SizedBox(height: 8),
        _buildLocationField(
          icon: Icons.location_on,
          text: widget.destinationName,
          isActive: true,
        ),
      ],
    );
  }

  Widget _buildLocationField({
    required IconData icon,
    required String text,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: isActive ? kButtonColor : Colors.grey, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isActive ? Colors.black87 : Colors.grey,
                fontSize: isActive ? 18 : 15,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRampSelector() {
    if (!_hasRamps) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Text(
          '이용 가능한 진입 경로가 없습니다.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '진입 경로를 선택하세요:',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: widget.ramps.map((ramp) {
              final isSelected = _selectedRampNodeId == ramp.nodeId;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ChoiceChip(
                  label: Text(ramp.locationDescription),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedRampNodeId = selected ? ramp.nodeId : null;
                    });
                  },
                  selectedColor: kButtonColor,
                  labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    final bool showNextButton = _hasRamps && !_isSecondStep;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed:
            _isLoading ? null : (showNextButton ? _goToNextStep : _requestRoute),
        style: ElevatedButton.styleFrom(
          backgroundColor: kButtonColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : Text(
                  showNextButton ? '다음' : '경로 안내 시작',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
        ),
      ),
    );
  }
}
