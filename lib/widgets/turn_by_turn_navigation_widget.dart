import 'dart:async';
import 'package:flutter/material.dart';
import 'package:friendsride_app/services/navigation_service.dart';

/// Widget pentru turn-by-turn navigation (Uber-like)
class TurnByTurnNavigationWidget extends StatefulWidget {
  final NavigationService navigationService;
  final bool isDriver;

  const TurnByTurnNavigationWidget({
    super.key,
    required this.navigationService,
    this.isDriver = false,
  });

  @override
  State<TurnByTurnNavigationWidget> createState() => _TurnByTurnNavigationWidgetState();
}

class _TurnByTurnNavigationWidgetState extends State<TurnByTurnNavigationWidget> {
  Map<String, dynamic>? _currentStatus;
  StreamSubscription? _navigationSubscription;

  @override
  void initState() {
    super.initState();
    _setupNavigationListener();
    _updateStatus();
  }

  void _setupNavigationListener() {
    widget.navigationService.onNavigationUpdate = (update) {
      if (mounted) {
        setState(() {
          _currentStatus = update;
        });
      }
    };
  }

  void _updateStatus() {
    final status = widget.navigationService.getNavigationStatus();
    if (mounted) {
      setState(() {
        _currentStatus = status;
      });
    }
  }

  @override
  void dispose() {
    _navigationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStatus == null || !(_currentStatus!['isNavigating'] ?? false)) {
      return const SizedBox.shrink();
    }

    final currentStep = _currentStatus!['currentStep'] ?? 0;
    final totalSteps = _currentStatus!['totalSteps'] ?? 0;
    final instruction = _currentStatus!['currentInstruction'] ?? 'No instruction';
    final routeSummary = _currentStatus!['routeSummary'] as Map<String, dynamic>?;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.1).round()),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.navigation,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Navigație',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const Spacer(),
              Text(
                '$currentStep / $totalSteps',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Current instruction
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  _getInstructionIcon(instruction),
                  color: Theme.of(context).colorScheme.primary,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    instruction,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Route summary
          if (routeSummary != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoChip(
                  context,
                  Icons.route,
                  '${((routeSummary['totalDistance'] ?? 0) / 1000).toStringAsFixed(1)} km',
                ),
                _buildInfoChip(
                  context,
                  Icons.access_time,
                  '${((routeSummary['totalDuration'] ?? 0) / 60).toStringAsFixed(0)} min',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getInstructionIcon(String instruction) {
    final lower = instruction.toLowerCase();
    if (lower.contains('left') || lower.contains('stânga')) {
      return Icons.turn_left;
    } else if (lower.contains('right') || lower.contains('dreapta')) {
      return Icons.turn_right;
    } else if (lower.contains('straight') || lower.contains('drept')) {
      return Icons.straight;
    } else if (lower.contains('arrive') || lower.contains('sosire')) {
      return Icons.flag;
    } else if (lower.contains('u-turn') || lower.contains('întoarcere')) {
      return Icons.u_turn_left;
    } else {
      return Icons.navigation;
    }
  }
}

