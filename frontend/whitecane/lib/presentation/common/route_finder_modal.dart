import 'package:flutter/material.dart';
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
  final String destinationNodeId;
  final List<RampInfo> ramps;
  final Future<CoordinateDto?> Function(String nodeId) onGetCoordinate;
  final void Function(List<CoordinateDto> route, CoordinateDto destination)
      onRouteDraw;

  const RouteFinderModal({
    super.key,
    required this.destinationName,
    required this.destinationNodeId,
    required this.ramps,
    required this.onGetCoordinate,
    required this.onRouteDraw,
  });

  static Future<void> showModal(
    BuildContext context, {
    required String destinationName,
    required String destinationNodeId,
    required List<RampInfo> ramps,
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
        destinationNodeId: destinationNodeId,
        ramps: ramps,
        onGetCoordinate: onGetCoordinate,
        onRouteDraw: onRouteDraw,
      ),
    );
  }

  @override
  State<RouteFinderModal> createState() => _RouteFinderModalState();
}

class _RouteFinderModalState extends State<RouteFinderModal> {
  final TextEditingController _startController =
      TextEditingController(text: '내 위치');
  String? _selectedRampNodeId;
  bool _isSecondStep = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startController.text = '내 위치';
  }

  @override
  void dispose() {
    _startController.dispose();
    super.dispose();
  }

  void _goToNextStep() {
    setState(() {
      _isSecondStep = true;
    });
  }

  Future<void> _requestRoute() async {
    if (_selectedRampNodeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('진입 경로를 선택해주세요.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final destination = await widget.onGetCoordinate(_selectedRampNodeId!);
      if (destination == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('목적지 좌표를 가져올 수 없습니다.')),
        );
        return;
      }

      // TODO: 실제 경로 계산 API 연동
      // 현재는 빈 경로 리스트를 반환 (경로 알고리즘 미구현)
      widget.onRouteDraw([], destination);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('경로 요청 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
            if (!_isSecondStep)
              _buildRouteInputs()
            else
              _buildRampSelector(),
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
      children: [
        _buildInputField(
          icon: Icons.my_location,
          controller: _startController,
          hintText: '출발지',
          isActive: false,
        ),
        const SizedBox(height: 8),
        _buildInputField(
          icon: Icons.location_on,
          controller: TextEditingController(text: widget.destinationName),
          hintText: '목적지',
          isActive: true,
        ),
      ],
    );
  }

  Widget _buildInputField({
    required IconData icon,
    required TextEditingController controller,
    required String hintText,
    required bool isActive,
  }) {
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: isActive ? kButtonColor : Colors.grey),
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildRampSelector() {
    if (widget.ramps.isEmpty) {
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
                  labelStyle:
                      TextStyle(color: isSelected ? Colors.white : Colors.black),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _isLoading
            ? null
            : (_isSecondStep ? _requestRoute : _goToNextStep),
        style: ElevatedButton.styleFrom(
          backgroundColor: kButtonColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : Text(
                  _isSecondStep ? '경로 안내 시작' : '다음',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
        ),
      ),
    );
  }
}
