import 'package:flutter/material.dart';
import 'package:whitecane/presentation/theme/color.dart';

class IndoorMapPage extends StatelessWidget {
  final String buildingName;
  final double startX;
  final double startY;
  final double endX;
  final double endY;

  const IndoorMapPage({
    super.key,
    required this.buildingName,
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '실내 경로 안내',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            Text(
              buildingName,
              style:
                  const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── 실내 지도 영역 ─────────────────────────────────────
          Expanded(
            child: _IndoorMapView(
              startX: startX,
              startY: startY,
              endX: endX,
              endY: endY,
            ),
          ),

          // ── 하단 경로 정보 카드 ────────────────────────────────
          _RouteInfoCard(
            startX: startX,
            startY: startY,
            endX: endX,
            endY: endY,
          ),
        ],
      ),
    );
  }
}

// ── 실내 지도 뷰 ──────────────────────────────────────────────────────────────

class _IndoorMapView extends StatelessWidget {
  final double startX;
  final double startY;
  final double endX;
  final double endY;

  const _IndoorMapView({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // 그리드 배경 (조감도 자리)
            Positioned.fill(
              child: CustomPaint(
                painter: _FloorPlanPlaceholderPainter(),
              ),
            ),

            // 경로 + 마커 (좌표 스케일 기반)
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return CustomPaint(
                    painter: _RouteMarkerPainter(
                      startX: startX,
                      startY: startY,
                      endX: endX,
                      endY: endY,
                      canvasSize: Size(
                          constraints.maxWidth, constraints.maxHeight),
                    ),
                  );
                },
              ),
            ),

            // 준비 중 안내 배너
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(153),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '실내 지도 데이터 준비 중입니다. 좌표 기반 미리보기입니다.',
                        style: TextStyle(
                            color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 범례
            Positioned(
              bottom: 12,
              right: 12,
              child: _Legend(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 그리드 배경 Painter ───────────────────────────────────────────────────────

class _FloorPlanPlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;

    const spacing = 40.0;

    // 세로선
    for (double x = spacing; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    // 가로선
    for (double y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 방 구획 예시 (추후 실제 도면으로 교체)
    final roomPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final rooms = [
      Rect.fromLTWH(spacing, spacing, size.width * 0.3, size.height * 0.3),
      Rect.fromLTWH(
          size.width * 0.5, spacing, size.width * 0.35, size.height * 0.25),
      Rect.fromLTWH(
          spacing, size.height * 0.55, size.width * 0.25, size.height * 0.3),
      Rect.fromLTWH(size.width * 0.4, size.height * 0.5, size.width * 0.45,
          size.height * 0.35),
    ];

    for (final room in rooms) {
      canvas.drawRect(room, roomPaint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── 경로 + 마커 Painter ───────────────────────────────────────────────────────

class _RouteMarkerPainter extends CustomPainter {
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final Size canvasSize;

  _RouteMarkerPainter({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.canvasSize,
  });

  // 입력 좌표를 캔버스 좌표로 변환 (패딩 40 적용)
  Offset _toCanvas(double x, double y, double minX, double maxX, double minY,
      double maxY) {
    const padding = 60.0;
    final rangeX = (maxX - minX).abs() < 1 ? 1.0 : (maxX - minX).abs();
    final rangeY = (maxY - minY).abs() < 1 ? 1.0 : (maxY - minY).abs();

    final cx = padding +
        (x - minX) / rangeX * (canvasSize.width - padding * 2);
    final cy = padding +
        (y - minY) / rangeY * (canvasSize.height - padding * 2);
    return Offset(cx, cy);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final minX = startX < endX ? startX : endX;
    final maxX = startX > endX ? startX : endX;
    final minY = startY < endY ? startY : endY;
    final maxY = startY > endY ? startY : endY;

    final startOffset = _toCanvas(startX, startY, minX, maxX, minY, maxY);
    final endOffset = _toCanvas(endX, endY, minX, maxX, minY, maxY);

    // 점선 경로
    final routePaint = Paint()
      ..color = kButtonColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    _drawDashedLine(canvas, startOffset, endOffset, routePaint);

    // 출발 마커 (초록 원)
    _drawMarker(canvas, startOffset,
        fillColor: const Color(0xFF34C759), label: '출발');

    // 도착 마커 (주황 원)
    _drawMarker(canvas, endOffset,
        fillColor: kButtonColor, label: '도착');
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashLength = 12.0;
    const gapLength = 6.0;

    final distance = (end - start).distance;
    if (distance < 1) return;

    final dx = (end.dx - start.dx) / distance;
    final dy = (end.dy - start.dy) / distance;

    double drawn = 0;
    bool drawing = true;
    var current = start;

    while (drawn < distance) {
      final segLen = drawing ? dashLength : gapLength;
      final step = (distance - drawn) < segLen ? (distance - drawn) : segLen;
      final next = Offset(current.dx + dx * step, current.dy + dy * step);

      if (drawing) canvas.drawLine(current, next, paint);

      current = next;
      drawn += step;
      drawing = !drawing;
    }
  }

  void _drawMarker(Canvas canvas, Offset center,
      {required Color fillColor, required String label}) {
    const radius = 14.0;

    // 그림자
    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(40)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center + const Offset(0, 2), radius, shadowPaint);

    // 원 배경
    final circlePaint = Paint()..color = fillColor;
    canvas.drawCircle(center, radius, circlePaint);

    // 흰 테두리
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, borderPaint);

    // 레이블
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_RouteMarkerPainter old) =>
      old.startX != startX ||
      old.startY != startY ||
      old.endX != endX ||
      old.endY != endY;
}

// ── 범례 ─────────────────────────────────────────────────────────────────────

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(230),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _legendItem(color: const Color(0xFF34C759), label: '출발'),
          const SizedBox(height: 4),
          _legendItem(color: kButtonColor, label: '도착'),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 20,
                height: 2,
                color: kButtonColor,
              ),
              const SizedBox(width: 6),
              const Text('경로', style: TextStyle(fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

// ── 하단 경로 정보 카드 ───────────────────────────────────────────────────────

class _RouteInfoCard extends StatelessWidget {
  final double startX;
  final double startY;
  final double endX;
  final double endY;

  const _RouteInfoCard({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
  });

  String _fmt(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 출발 → 도착
          Row(
            children: [
              _coordChip(
                icon: Icons.trip_origin,
                iconColor: const Color(0xFF34C759),
                label: '출발',
                coord: '(${_fmt(startX)}, ${_fmt(startY)})',
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward,
                    size: 16, color: Colors.grey),
              ),
              _coordChip(
                icon: Icons.location_on,
                iconColor: kButtonColor,
                label: '도착',
                coord: '(${_fmt(endX)}, ${_fmt(endY)})',
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 상태 메시지
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.construction,
                    size: 16, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '실내 경로 알고리즘 및 지도 데이터 준비 중입니다.',
                    style: TextStyle(
                        fontSize: 13, color: Colors.orange.shade800),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _coordChip({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String coord,
  }) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey)),
                Text(
                  coord,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
