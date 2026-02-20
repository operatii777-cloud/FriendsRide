// lib/widgets/custom_card.dart

import 'package:flutter/material.dart';
import 'package:friendsride_app/theme/app_colors.dart';
import 'package:friendsride_app/theme/app_text_styles.dart';
import 'package:friendsride_app/theme/app_constants.dart';
// Asigură-te că ai acest import

enum CardType { standard, elevated, outlined, gradient }

class CustomCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final CardType type;
  final LinearGradient? gradient;
  final Color? backgroundColor;
  final double? elevation;
  final Border? border;
  final double? borderRadius;
  final bool isSelected;
  final bool showShadow;

  const CustomCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.type = CardType.standard,
    this.gradient,
    this.backgroundColor,
    this.elevation,
    this.border,
    this.borderRadius,
    this.isSelected = false,
    this.showShadow = true,
  });

  @override
  State<CustomCard> createState() => _CustomCardState();
}

class _CustomCardState extends State<CustomCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppConstants.animationMedium,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _elevationAnimation = Tween<double>(
      begin: _getBaseElevation(),
      end: _getBaseElevation() + 4,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  double _getBaseElevation() {
    if (!widget.showShadow) return 0;
    if (widget.elevation != null) return widget.elevation!;
    
    switch (widget.type) {
      case CardType.standard:
        return AppConstants.elevationS;
      case CardType.elevated:
        return AppConstants.elevationM;
      case CardType.outlined:
        return 0;
      case CardType.gradient:
        return AppConstants.elevationM;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: widget.margin,
              decoration: BoxDecoration(
                gradient: widget.type == CardType.gradient 
                    ? (widget.gradient ?? AppColors.primaryGradient)
                    : null,
                color: widget.type != CardType.gradient 
                    ? (widget.backgroundColor ?? _getBackgroundColor())
                    : null,
                borderRadius: BorderRadius.circular(
                  widget.borderRadius ?? AppConstants.radiusL,
                ),
                border: widget.border ?? _getBorder(),
                boxShadow: widget.showShadow && _elevationAnimation.value > 0
                    ? [
                        BoxShadow(
                          color: widget.isSelected 
                              ? AppColors.primary.withValues(alpha: 0.3)
                              : AppColors.shadowLight,
                          blurRadius: _elevationAnimation.value * 2,
                          offset: Offset(0, _elevationAnimation.value),
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(
                  widget.borderRadius ?? AppConstants.radiusL,
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(
                    widget.borderRadius ?? AppConstants.radiusL,
                  ),
                  onTap: widget.onTap,
                  child: Padding(
                    padding: widget.padding ?? const EdgeInsets.all(AppConstants.spacingM),
                    child: widget.child,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _onHover(bool isHovering) {
    if (widget.onTap == null) return;
    
    if (isHovering) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  Color _getBackgroundColor() {
    if (widget.isSelected) {
      return AppColors.primary.withValues(alpha: 0.1);
    }
    
    switch (widget.type) {
      case CardType.standard:
      case CardType.elevated:
        return AppColors.surface;
      case CardType.outlined:
        return Colors.transparent;
      case CardType.gradient:
        return Colors.transparent;
    }
  }

  Border? _getBorder() {
    if (widget.isSelected) {
      return Border.all(
        color: AppColors.primary,
        width: 2,
      );
    }
    
    switch (widget.type) {
      case CardType.outlined:
        return Border.all(
          color: AppColors.textDisabled.withValues(alpha: 0.3),
          width: 1,
        );
      default:
        return null;
    }
  }
}

class InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;
  final Color? iconColor;
  final LinearGradient? gradient;
  final VoidCallback? onTap;
  final Widget? trailing;

  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
    this.iconColor,
    this.gradient,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      type: gradient != null ? CardType.gradient : CardType.elevated,
      gradient: gradient,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: gradient != null 
                  ? Colors.white.withValues(alpha: 0.2)
                  : (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
            ),
            child: Icon(
              icon,
              color: gradient != null 
                  ? Colors.white
                  : (iconColor ?? AppColors.primary),
              size: AppConstants.iconM,
            ),
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: gradient != null 
                        ? Colors.white.withValues(alpha: 0.9)
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingXS),
                Text(
                  value,
                  style: AppTextStyles.headingMedium.copyWith(
                    color: gradient != null 
                        ? Colors.white
                        : AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppConstants.spacingXS),
                  Text(
                    subtitle!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: gradient != null 
                          ? Colors.white.withValues(alpha: 0.8)
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppConstants.spacingM),
            trailing!,
          ] else if (onTap != null) ...[
            const SizedBox(width: AppConstants.spacingM),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: gradient != null 
                  ? Colors.white.withValues(alpha: 0.8)
                  : AppColors.textSecondary,
              size: AppConstants.iconS,
            ),
          ],
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final double? trend;
  final bool isPositiveTrend;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.iconColor = AppColors.primary,
    this.trend,
    this.isPositiveTrend = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      type: CardType.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingS),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusS),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: AppConstants.iconM,
                ),
              ),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingS,
                    vertical: AppConstants.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: (isPositiveTrend ? AppColors.success : AppColors.error)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppConstants.radiusS),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositiveTrend 
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        color: isPositiveTrend ? AppColors.success : AppColors.error,
                        size: AppConstants.iconS,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${trend!.abs().toStringAsFixed(1)}%',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isPositiveTrend ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            value,
            style: AppTextStyles.displayMedium.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.spacingXS),
          Text(
            title,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppConstants.spacingXS),
            Text(
              subtitle!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String primaryActionText;
  final String? secondaryActionText;
  final VoidCallback onPrimaryAction;
  final VoidCallback? onSecondaryAction;
  final Color? accentColor;
  final bool isEnabled;

  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.primaryActionText,
    this.secondaryActionText,
    required this.onPrimaryAction,
    this.onSecondaryAction,
    this.accentColor,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.primary;
    
    return CustomCard(
      type: CardType.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: AppConstants.iconL,
                ),
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.headingMedium,
                    ),
                    const SizedBox(height: AppConstants.spacingXS),
                    Text(
                      description,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingL),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  ),
                  child: ElevatedButton(
                    onPressed: isEnabled ? onPrimaryAction : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppConstants.spacingM,
                      ),
                    ),
                    child: Text(
                      primaryActionText,
                      style: AppTextStyles.buttonMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              if (secondaryActionText != null && onSecondaryAction != null) ...[
                const SizedBox(width: AppConstants.spacingM),
                Expanded(
                  child: OutlinedButton(
                    onPressed: isEnabled ? onSecondaryAction : null,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: color),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppConstants.spacingM,
                      ),
                    ),
                    child: Text(
                      secondaryActionText!,
                      style: AppTextStyles.buttonMedium.copyWith(
                        color: color,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      type: CardType.outlined,
      padding: const EdgeInsets.all(AppConstants.spacingXL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.textDisabled.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: AppConstants.iconXL,
              color: AppColors.textDisabled,
            ),
          ),
          const SizedBox(height: AppConstants.spacingL),
          Text(
            title,
            style: AppTextStyles.headingMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            description,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (actionText != null && onAction != null) ...[
            const SizedBox(height: AppConstants.spacingL),
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
              child: ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                child: Text(
                  actionText!,
                  style: AppTextStyles.buttonMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}