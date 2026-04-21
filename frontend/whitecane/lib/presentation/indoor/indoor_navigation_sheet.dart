import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:whitecane/presentation/indoor/indoor_map_page.dart';
import 'package:whitecane/presentation/theme/color.dart';

class IndoorNavigationSheet extends StatefulWidget {
  final String buildingName;

  const IndoorNavigationSheet({super.key, required this.buildingName});

  static Future<void> showSheet(
    BuildContext context, {
    required String buildingName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) =>
          IndoorNavigationSheet(buildingName: buildingName),
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
              const SizedBox(height: 20),
              _buildCoordinateSection(
                label: '출발지',
                icon: Icons.trip_origin,
                iconColor: const Color(0xFF34C759),
                xController: _startXController,
                yController: _startYController,
              ),
              const SizedBox(height: 16),
              _buildCoordinateSection(
                label: '도착지',
                icon: Icons.location_on,
                iconColor: kButtonColor,
                xController: _endXController,
                yController: _endYController,
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

  Widget _buildCoordinateSection({
    required String label,
    required IconData icon,
    required Color iconColor,
    required TextEditingController xController,
    required TextEditingController yController,
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
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildCoordField(
                controller: xController,
                hint: 'X 좌표',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCoordField(
                controller: yController,
                hint: 'Y 좌표',
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
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
      ],
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: kButtonColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return '입력 필요';
        if (double.tryParse(value) == null) return '숫자 입력';
        return null;
      },
    );
  }
}
