import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Model pentru un punct de pe heatmap
class HeatmapPoint {
  final double latitude;
  final double longitude;
  final double intensity; // 0.0 – 1.0

  const HeatmapPoint({
    required this.latitude,
    required this.longitude,
    required this.intensity,
  });
}

/// Widget care simulează o hartă de cerere (heatmap)
class HeatmapWidget extends StatelessWidget {
  final List<HeatmapPoint> points;
  final double height;

  const HeatmapWidget({
    super.key,
    required this.points,
    this.height = 280,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.map_outlined, color: Color(0xFF1976D2)),
              const SizedBox(width: 8),
              Text(
                'Hartă cerere',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: height,
            color: const Color(0xFFE8F4FD),
            child: Stack(
              children: [
                _buildGridBackground(),
                if (points.isNotEmpty)
                  CustomPaint(
                    painter: _HeatmapPainter(points: points),
                    child: const SizedBox.expand(),
                  ),
                if (points.isEmpty) _buildEmptyState(),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _buildLegend(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGridBackground() {
    return CustomPaint(
      painter: _GridPainter(),
      child: const SizedBox.expand(),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.map_outlined, size: 40, color: Colors.grey),
          SizedBox(height: 8),
          Text(
            'Nicio dată disponibilă',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLegendItem(color: const Color(0xFF4CAF50), label: 'Cerere mică'),
          const SizedBox(height: 4),
          _buildLegendItem(color: const Color(0xFFFFC107), label: 'Cerere medie'),
          const SizedBox(height: 4),
          _buildLegendItem(color: const Color(0xFFF44336), label: 'Cerere mare'),
        ],
      ),
    );
  }

  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.8),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

/// CustomPainter pentru grid-ul de fundal
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.08)
      ..strokeWidth = 0.5;

    const step = 30.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// CustomPainter pentru punctele heatmap
class _HeatmapPainter extends CustomPainter {
  final List<HeatmapPoint> points;

  _HeatmapPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    // Normalizează coordonatele în spațiul widget
    final minLat = points.map((p) => p.latitude).reduce(math.min);
    final maxLat = points.map((p) => p.latitude).reduce(math.max);
    final minLon = points.map((p) => p.longitude).reduce(math.min);
    final maxLon = points.map((p) => p.longitude).reduce(math.max);

    final latRange = (maxLat - minLat).abs();
    final lonRange = (maxLon - minLon).abs();
    // Când toate punctele au aceleași coordonate, le centrăm în widget
    final singlePoint = latRange < 0.0001 && lonRange < 0.0001;

    for (final point in points) {
      double x, y;
      if (singlePoint) {
        x = size.width / 2;
        y = size.height / 2;
      } else {
        x = lonRange > 0.0001
            ? ((point.longitude - minLon) / lonRange) * (size.width - 40) + 20
            : size.width / 2;
        y = latRange > 0.0001
            ? (1.0 - (point.latitude - minLat) / latRange) * (size.height - 40) + 20
            : size.height / 2;
      }

      final color = _intensityToColor(point.intensity);
      final radius = 20.0 + point.intensity * 30.0;

      final gradient = RadialGradient(
        colors: [
          color.withValues(alpha: 0.6),
          color.withValues(alpha: 0.0),
        ],
      );

      final rect = Rect.fromCircle(center: Offset(x, y), radius: radius);
      final paint = Paint()..shader = gradient.createShader(rect);

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  Color _intensityToColor(double intensity) {
    if (intensity < 0.33) return const Color(0xFF4CAF50); // verde - cerere mică
    if (intensity < 0.66) return const Color(0xFFFFC107); // galben - cerere medie
    return const Color(0xFFF44336); // roșu - cerere mare
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter oldDelegate) =>
      oldDelegate.points != points;
}
