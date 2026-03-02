import 'package:flutter/material.dart';
import 'package:friendsride_app/theme/app_colors.dart';
import 'package:friendsride_app/theme/app_text_styles.dart';

/// Model pentru un stop (oprire) al cursei.
class RideStop {
  final String id;
  final String address;

  const RideStop({required this.id, required this.address});

  RideStop copyWith({String? id, String? address}) {
    return RideStop(id: id ?? this.id, address: address ?? this.address);
  }
}

/// Widget pentru gestionarea mai multor opriri (stops) ale cursei.
/// Permite reordonare, adăugare și ștergere de opriri intermediare (max 5).
class MultipleStopsWidget extends StatefulWidget {
  final String startAddress;
  final String endAddress;
  final List<RideStop> initialStops;
  final ValueChanged<List<RideStop>>? onStopsChanged;

  const MultipleStopsWidget({
    super.key,
    required this.startAddress,
    required this.endAddress,
    this.initialStops = const [],
    this.onStopsChanged,
  });

  @override
  State<MultipleStopsWidget> createState() => _MultipleStopsWidgetState();
}

class _MultipleStopsWidgetState extends State<MultipleStopsWidget> {
  late List<RideStop> _stops;
  static const int _maxStops = 5;

  @override
  void initState() {
    super.initState();
    _stops = List.from(widget.initialStops);
  }

  void _notifyChange() {
    widget.onStopsChanged?.call(List.unmodifiable(_stops));
  }

  void _addStop() {
    if (_stops.length >= _maxStops) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maxim 5 opriri intermediare.')),
      );
      return;
    }
    _showAddStopDialog();
  }

  void _showAddStopDialog({int? editIndex}) {
    final ctrl = TextEditingController(
      text: editIndex != null ? _stops[editIndex].address : '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          editIndex != null ? 'Editează oprire' : 'Adaugă oprire',
          style: AppTextStyles.heading4,
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Adresă*',
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Anulează'),
          ),
          ElevatedButton(
            onPressed: () {
              final addr = ctrl.text.trim();
              if (addr.isEmpty) return;
              Navigator.pop(ctx);
              setState(() {
                if (editIndex != null) {
                  _stops[editIndex] =
                      _stops[editIndex].copyWith(address: addr);
                } else {
                  _stops.add(RideStop(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    address: addr,
                  ));
                }
              });
              _notifyChange();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _removeStop(int index) {
    setState(() => _stops.removeAt(index));
    _notifyChange();
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final stop = _stops.removeAt(oldIndex);
      _stops.insert(newIndex, stop);
    });
    _notifyChange();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Start point
        _AddressRow(
          icon: Icons.circle,
          iconColor: AppColors.secondary,
          label: 'Pornire',
          address: widget.startAddress,
        ),

        const Padding(
          padding: EdgeInsets.only(left: 11),
          child: SizedBox(
            height: 8,
            child: VerticalDivider(thickness: 2, color: Color(0xFFE0E0E0)),
          ),
        ),

        // Intermediate stops (reorderable)
        if (_stops.isNotEmpty)
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _stops.length,
            onReorder: _onReorder,
            itemBuilder: (_, i) => Dismissible(
              key: ValueKey(_stops[i].id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                color: AppColors.error.withOpacity(0.15),
                child: Icon(Icons.delete, color: AppColors.error),
              ),
              onDismissed: (_) => _removeStop(i),
              child: Column(
                children: [
                  _AddressRow(
                    icon: Icons.stop_circle_outlined,
                    iconColor: AppColors.warning,
                    label: 'Oprire ${i + 1}',
                    address: _stops[i].address,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _showAddStopDialog(editIndex: i),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          color: AppColors.textSecondary,
                        ),
                        ReorderableDragStartListener(
                          index: i,
                          child: const Icon(Icons.drag_handle,
                              color: Color(0xFFBDBDBD)),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 11),
                    child: SizedBox(
                      height: 8,
                      child: VerticalDivider(
                          thickness: 2, color: Color(0xFFE0E0E0)),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Add stop button
        if (_stops.length < _maxStops)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: InkWell(
              onTap: _addStop,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline,
                        color: AppColors.primary, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Adaugă oprire intermediară',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),
          ),

        const Padding(
          padding: EdgeInsets.only(left: 11),
          child: SizedBox(
            height: 8,
            child: VerticalDivider(thickness: 2, color: Color(0xFFE0E0E0)),
          ),
        ),

        // End point
        _AddressRow(
          icon: Icons.location_on,
          iconColor: AppColors.error,
          label: 'Destinație',
          address: widget.endAddress,
        ),
      ],
    );
  }
}

class _AddressRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String address;
  final Widget? trailing;

  const _AddressRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.address,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
              Text(
                address,
                style: AppTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
