import 'package:flutter/material.dart';
import 'package:friendsride_app/theme/app_colors.dart';
import 'package:friendsride_app/theme/app_text_styles.dart';

/// Widget pentru gestionarea mai multor opriri (multiple stops)
class MultipleStopsWidget extends StatefulWidget {
  final List<String> stops;
  final ValueChanged<List<String>> onStopsChanged;
  final int maxStops;

  const MultipleStopsWidget({
    super.key,
    required this.stops,
    required this.onStopsChanged,
    this.maxStops = 5,
  });

  @override
  State<MultipleStopsWidget> createState() => _MultipleStopsWidgetState();
}

class _MultipleStopsWidgetState extends State<MultipleStopsWidget> {
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = widget.stops
        .map((s) => TextEditingController(text: s))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> get _currentStops =>
      _controllers.map((c) => c.text.trim()).toList();

  void _addStop() {
    if (_controllers.length >= widget.maxStops) return;
    setState(() {
      // Inserează oprire intermediară înainte de destinație (ultimul element)
      final insertIndex = _controllers.length - 1;
      _controllers.insert(insertIndex, TextEditingController());
    });
    widget.onStopsChanged(_currentStops);
  }

  void _removeStop(int index) {
    // Nu permite eliminarea pickup (0) sau destinației (ultimul)
    if (index == 0 || index == _controllers.length - 1) return;
    setState(() {
      _controllers[index].dispose();
      _controllers.removeAt(index);
    });
    widget.onStopsChanged(_currentStops);
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (oldIndex == 0 || newIndex == 0) return;
    if (oldIndex == _controllers.length - 1 ||
        newIndex == _controllers.length) return;

    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _controllers.removeAt(oldIndex);
      _controllers.insert(newIndex, item);
    });
    widget.onStopsChanged(_currentStops);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.alt_route, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('Opriri', style: AppTextStyles.headingSmall),
            const Spacer(),
            Text(
              '${_controllers.length} / ${widget.maxStops}',
              style: AppTextStyles.labelSmall,
            ),
          ],
        ),
        const SizedBox(height: 12),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _controllers.length,
          onReorder: _onReorder,
          proxyDecorator: (child, index, animation) => Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(10),
            child: child,
          ),
          itemBuilder: (context, index) {
            return _buildStopItem(index, key: ValueKey(index));
          },
        ),
        if (_controllers.length < widget.maxStops) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _addStop,
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text('Adaugă oprire'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStopItem(int index, {required Key key}) {
    final isFirst = index == 0;
    final isLast = index == _controllers.length - 1;
    final label = isFirst
        ? 'Punct de plecare'
        : isLast
            ? 'Destinație'
            : 'Oprire ${index}';

    final dotColor = isFirst
        ? AppColors.primary
        : isLast
            ? AppColors.error
            : AppColors.secondary;

    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: isFirst || isLast ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius:
                      isFirst || isLast ? null : BorderRadius.circular(3),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 20,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  color: AppColors.textDisabled,
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _controllers[index],
              decoration: InputDecoration(
                labelText: label,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (_) => widget.onStopsChanged(_currentStops),
            ),
          ),
          if (!isFirst && !isLast) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              color: AppColors.error,
              tooltip: 'Elimină oprire',
              onPressed: () => _removeStop(index),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ] else
            const SizedBox(width: 36),
        ],
      ),
    );
  }
}
