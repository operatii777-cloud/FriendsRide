import 'package:flutter/material.dart';
import 'package:friendsride_app/theme/app_colors.dart';
import 'package:friendsride_app/theme/app_text_styles.dart';

/// Model pentru un punct de pe harta de cerere (heatmap).
class HeatmapPoint {
  final double latitude;
  final double longitude;
  /// Intensitate între 0.0 și 1.0
  final double intensity;

  const HeatmapPoint({
    required this.latitude,
    required this.longitude,
    required this.intensity,
  });
}

/// Widget care afișează o hartă de căldură (heatmap) a zonelor cu cerere mare.
class HeatmapWidget extends StatelessWidget {
  final List<HeatmapPoint> points;
  final double minLat;
  final double maxLat;
  final double minLon;
  final double maxLon;
  final bool showLegend;
  final bool showGrid;

  const HeatmapWidget({
    super.key,
    required this.points,
    required this.minLat,
    required this.maxLat,
    required this.minLon,
    required this.maxLon,
    this.showLegend = true,
    this.showGrid = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CustomPaint(
              painter: _HeatmapPainter(
                points: points,
                minLat: minLat,
                maxLat: maxLat,
                minLon: minLon,
                maxLon: maxLon,
                showGrid: showGrid,
              ),
              child: Container(),
            ),
          ),
        ),
        if (showLegend) ...[
          const SizedBox(height: 12),
          _buildLegend(),
        ],
      ],
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(color: Colors.green, label: 'Cerere mică'),
        const SizedBox(width: 16),
        _LegendItem(color: Colors.yellow.shade700, label: 'Medie'),
        const SizedBox(width: 16),
        _LegendItem(color: Colors.red, label: 'Cerere mare'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color.withOpacity(0.75),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  final List<HeatmapPoint> points;
  final double minLat;
  final double maxLat;
  final double minLon;
  final double maxLon;
  final bool showGrid;

  _HeatmapPainter({
    required this.points,
    required this.minLat,
    required this.maxLat,
    required this.minLon,
    required this.maxLon,
    required this.showGrid,
  });

  Offset _project(double lat, double lon, Size size) {
    final latRange = maxLat - minLat;
    final lonRange = maxLon - minLon;
    if (latRange == 0 || lonRange == 0) return Offset(size.width / 2, size.height / 2);
    final x = (lon - minLon) / lonRange * size.width;
    final y = (1 - (lat - minLat) / latRange) * size.height;
    return Offset(x, y);
  }

  Color _intensityToColor(double intensity) {
    final t = intensity.clamp(0.0, 1.0);
    if (t < 0.5) {
      return Color.lerp(Colors.green, Colors.yellow, t * 2)!;
    } else {
      return Color.lerp(Colors.yellow, Colors.red, (t - 0.5) * 2)!;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFE8F4FD),
    );

    // Grid
    if (showGrid) {
      _GridPainter(gridSize: 40).paint(canvas, size);
    }

    // Heat blobs
    for (final point in points) {
      final offset = _project(point.latitude, point.longitude, size);
      final radius = 30.0 + point.intensity * 40.0;
      final color = _intensityToColor(point.intensity);

      final gradient = RadialGradient(
        colors: [
          color.withOpacity(0.7 * point.intensity + 0.15),
          color.withOpacity(0.0),
        ],
      );

      final paint = Paint()
        ..shader = gradient.createShader(Rect.fromCircle(
          center: offset,
          radius: radius,
        ));

      canvas.drawCircle(offset, radius, paint);
    }

    // Points
    for (final point in points) {
      final offset = _project(point.latitude, point.longitude, size);
      canvas.drawCircle(
        offset,
        4 + point.intensity * 4,
        Paint()
          ..color = _intensityToColor(point.intensity)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_HeatmapPainter old) =>
      old.points != points ||
      old.minLat != minLat ||
      old.maxLat != maxLat ||
      old.minLon != minLon ||
      old.maxLon != maxLon;
}

class _GridPainter {
  final double gridSize;
  const _GridPainter({this.gridSize = 40});

  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueGrey.withOpacity(0.08)
      ..strokeWidth = 0.8;

    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
}
