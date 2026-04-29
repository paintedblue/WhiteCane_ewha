import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:whitecane/domain/model/indoor_room.dart';
import 'package:whitecane/presentation/indoor/indoor_map_page.dart';
import 'package:whitecane/presentation/theme/color.dart';

class IndoorNavigationSheet extends StatefulWidget {
  final String buildingName;

  /// 미리 설정된 목적지 방. null이면 사용자가 직접 입력.
  final IndoorRoom? destinationRoom;

  const IndoorNavigationSheet({
    super.key,
    required this.buildingName,
    this.destinationRoom,
  });

  static Future<void> showSheet(
    BuildContext context, {
    required String buildingName,
    IndoorRoom? destinationRoom,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => IndoorNavigationSheet(
        buildingName: buildingName,
        destinationRoom: destinationRoom,
      ),
    );
  }

  @override
  State<IndoorNavigationSheet> createState() => _IndoorNavigationSheetState();
}

class _IndoorNavigationSheetState extends State<IndoorNavigationSheet> {
  final _startXController = TextEditingController();
  final _startYController = TextEditingController();
  final _endXController = TextEditingController();
  final _endYController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool get _hasPresetDestination => widget.destinationRoom != null;

  @override
  void initState() {
    super.initState();
    // 출발지 기본값: 건물 입구 (0, 0)
    _startXController.text = '0.0';
    _startYController.text = '0.0';

    // 목적지 사전 설정
    if (_hasPresetDestination) {
      _endXController.text = widget.destinationRoom!.indoorX.toString();
      _endYController.text = widget.destinationRoom!.indoorY.toString();
    }
  }

  @override
  void dispose() {
    _startXController.dispose();
    _startYController.dispose();
    _endXController.dispose();
    _endYController.dispose();
    super.dispose();
  }

  void _startNavigation() {
    if (!_formKey.currentState!.validate()) return;

    final startX = double.parse(_startXController.text);
    final startY = double.parse(_startYController.text);
    final endX = double.parse(_endXController.text);
    final endY = double.parse(_endYController.text);

    Navigator.pop(context);
    Get.to(
      () => IndoorMapPage(
        buildingName: widget.buildingName,
        destinationRoom: widget.destinationRoom,
        startX: startX,
        startY: startY,
        endX: endX,
        endY: endY,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 4),
              Text(
                widget.buildingName,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              if (_hasPresetDestination) ...[
                const SizedBox(height: 8),
                _buildPresetDestinationBadge(),
              ],
              const SizedBox(height: 20),
              _buildCoordinateSection(
                label: '출발지',
                icon: Icons.trip_origin,
                iconColor: const Color(0xFF34C759),
                xController: _startXController,
                yController: _startYController,
                readOnly: false,
              ),
              const SizedBox(height: 16),
              _buildCoordinateSection(
                label: '도착지',
                icon: Icons.location_on,
                iconColor: kButtonColor,
                xController: _endXController,
                yController: _endYController,
                readOnly: _hasPresetDestination,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startNavigation,
                  icon: const Icon(Icons.maps_home_work, color: Colors.white),
                  label: const Text(
                    '실내 경로 안내 시작',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kButtonColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: const Text(
            '실내 경로 안내',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildPresetDestinationBadge() {
    final room = widget.destinationRoom!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF5856D6).withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFF5856D6).withAlpha(80), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.maps_home_work,
              size: 14, color: Color(0xFF5856D6)),
          const SizedBox(width: 4),
          Text(
            '목적지: ${room.fullLabel}',
            style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF5856D6),
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildCoordinateSection({
    required String label,
    required IconData icon,
    required Color iconColor,
    required TextEditingController xController,
    required TextEditingController yController,
    required bool readOnly,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            if (readOnly) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '자동 설정',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildCoordField(
                controller: xController,
                hint: 'X 좌표',
                readOnly: readOnly,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCoordField(
                controller: yController,
                hint: 'Y 좌표',
                readOnly: readOnly,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCoordField({
    required TextEditingController controller,
    required String hint,
    required bool readOnly,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: readOnly
          ? null
          : const TextInputType.numberWithOptions(decimal: true, signed: true),
      inputFormatters: readOnly
          ? null
          : [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*'))],
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        filled: readOnly,
        fillColor: readOnly ? Colors.grey.shade50 : null,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: readOnly ? Colors.grey.shade200 : Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: readOnly ? Colors.grey.shade300 : kButtonColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
      style: TextStyle(
        color: readOnly ? Colors.grey.shade500 : Colors.black87,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return '입력 필요';
        if (double.tryParse(value) == null) return '숫자 입력';
        return null;
      },
    );
  }
}
