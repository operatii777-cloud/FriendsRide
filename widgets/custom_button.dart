// lib/widgets/custom_button.dart

import 'package:flutter/material.dart';
import 'package:friendsride_app/theme/app_colors.dart';
import 'package:friendsride_app/theme/app_text_styles.dart';
import 'package:friendsride_app/theme/app_constants.dart';
// Asigură-te că ai acest import

enum ButtonSize { small, medium, large }
enum ButtonType { primary, secondary, outline, text, danger, success }

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final ButtonSize size;
  final IconData? icon;
  final bool iconRight;
  final bool isLoading;
  final bool isFullWidth;
  final LinearGradient? gradient;
  final double? elevation;
  final EdgeInsetsGeometry? padding;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.iconRight = false,
    this.isLoading = false,
    this.isFullWidth = false,
    this.gradient,
    this.elevation,
    this.padding,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppConstants.animationFast,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _animationController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _resetAnimation();
  }

  void _onTapCancel() {
    _resetAnimation();
  }

  void _resetAnimation() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final buttonConfig = _getButtonConfig();
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.isFullWidth ? double.infinity : null,
            height: _getButtonHeight(),
            decoration: BoxDecoration(
              gradient: widget.gradient ?? buttonConfig.gradient,
              borderRadius: BorderRadius.circular(buttonConfig.borderRadius),
              boxShadow: widget.isLoading || widget.onPressed == null
                  ? null
                  : [
                      BoxShadow(
                        color: buttonConfig.shadowColor,
                        blurRadius: widget.elevation ?? buttonConfig.elevation,
                        offset: Offset(0, (widget.elevation ?? buttonConfig.elevation) / 2),
                      ),
                    ],
              border: buttonConfig.border,
            ),
            child: Material(
              color: widget.gradient != null || buttonConfig.gradient != null 
                  ? Colors.transparent 
                  : buttonConfig.backgroundColor,
              borderRadius: BorderRadius.circular(buttonConfig.borderRadius),
              child: InkWell(
                borderRadius: BorderRadius.circular(buttonConfig.borderRadius),
                onTap: widget.isLoading ? null : widget.onPressed,
                child: GestureDetector(
                  onTapDown: _onTapDown,
                  onTapUp: _onTapUp,
                  onTapCancel: _onTapCancel,
                  child: Container(
                    padding: widget.padding ?? _getButtonPadding(),
                    child: _buildButtonContent(buttonConfig),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildButtonContent(ButtonConfig config) {
    if (widget.isLoading) {
      return _buildLoadingContent(config);
    }

    final children = <Widget>[];
    
    if (widget.icon != null && !widget.iconRight) {
      children.add(Icon(
        widget.icon,
        size: _getIconSize(),
        color: config.textColor,
      ));
      children.add(SizedBox(width: AppConstants.spacingS));
    }
    
    children.add(
      Flexible(
        child: Text(
          widget.text,
          style: _getTextStyle().copyWith(color: config.textColor),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
    
    if (widget.icon != null && widget.iconRight) {
      children.add(SizedBox(width: AppConstants.spacingS));
      children.add(Icon(
        widget.icon,
        size: _getIconSize(),
        color: config.textColor,
      ));
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  Widget _buildLoadingContent(ButtonConfig config) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: _getIconSize(),
          height: _getIconSize(),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(config.textColor),
          ),
        ),
        SizedBox(width: AppConstants.spacingS),
        Text(
          'Se încarcă...',
          style: _getTextStyle().copyWith(color: config.textColor),
        ),
      ],
    );
  }

  ButtonConfig _getButtonConfig() {
    switch (widget.type) {
      case ButtonType.primary:
        return ButtonConfig(
          backgroundColor: AppColors.primary,
          textColor: AppColors.textOnPrimary,
          gradient: AppColors.primaryGradient,
          shadowColor: AppColors.primary.withValues(alpha: 0.3),
          borderRadius: AppConstants.radiusM,
          elevation: AppConstants.elevationS,
        );
        
      case ButtonType.secondary:
        return ButtonConfig(
          backgroundColor: AppColors.secondary,
          textColor: AppColors.textOnPrimary,
          gradient: AppColors.secondaryGradient,
          shadowColor: AppColors.secondary.withValues(alpha: 0.3),
          borderRadius: AppConstants.radiusM,
          elevation: AppConstants.elevationS,
        );
        
      case ButtonType.outline:
        return ButtonConfig(
          backgroundColor: Colors.transparent,
          textColor: AppColors.primary,
          border: Border.all(color: AppColors.primary, width: 2),
          shadowColor: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: AppConstants.radiusM,
          elevation: 0,
        );
        
      case ButtonType.text:
        return ButtonConfig(
          backgroundColor: Colors.transparent,
          textColor: AppColors.primary,
          shadowColor: Colors.transparent,
          borderRadius: AppConstants.radiusM,
          elevation: 0,
        );
        
      case ButtonType.danger:
        return ButtonConfig(
          backgroundColor: AppColors.error,
          textColor: AppColors.textOnPrimary,
          gradient: LinearGradient(
            colors: [AppColors.error, AppColors.error.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shadowColor: AppColors.error.withValues(alpha: 0.3),
          borderRadius: AppConstants.radiusM,
          elevation: AppConstants.elevationS,
        );
        
      case ButtonType.success:
        return ButtonConfig(
          backgroundColor: AppColors.success,
          textColor: AppColors.textOnPrimary,
          gradient: LinearGradient(
            colors: [AppColors.success, AppColors.secondaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shadowColor: AppColors.success.withValues(alpha: 0.3),
          borderRadius: AppConstants.radiusM,
          elevation: AppConstants.elevationS,
        );
    }
  }

  double _getButtonHeight() {
    switch (widget.size) {
      case ButtonSize.small:
        return AppConstants.buttonHeightS;
      case ButtonSize.medium:
        return AppConstants.buttonHeightM;
      case ButtonSize.large:
        return AppConstants.buttonHeightL;
    }
  }

  EdgeInsetsGeometry _getButtonPadding() {
    switch (widget.size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingM,
          vertical: AppConstants.spacingS,
        );
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingL,
          vertical: AppConstants.spacingM,
        );
      case ButtonSize.large:
        return const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingXL,
          vertical: AppConstants.spacingM,
        );
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case ButtonSize.small:
        return AppConstants.iconS;
      case ButtonSize.medium:
        return AppConstants.iconS;
      case ButtonSize.large:
        return AppConstants.iconM;
    }
  }

  TextStyle _getTextStyle() {
    switch (widget.size) {
      case ButtonSize.small:
        return AppTextStyles.buttonSmall;
      case ButtonSize.medium:
        return AppTextStyles.buttonMedium;
      case ButtonSize.large:
        return AppTextStyles.buttonLarge;
    }
  }
}

class CustomFloatingActionButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;
  final LinearGradient? gradient;
  final double size;
  final bool mini;

  const CustomFloatingActionButton({
    super.key,
    this.onPressed,
    required this.icon,
    this.tooltip,
    this.gradient,
    this.size = 56.0,
    this.mini = false,
  });

  @override
  State<CustomFloatingActionButton> createState() => _CustomFloatingActionButtonState();
}

class _CustomFloatingActionButtonState extends State<CustomFloatingActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppConstants.animationFast,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.mini ? 40.0 : widget.size;
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: widget.gradient ?? AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: widget.onPressed,
                onTapDown: (_) => _animationController.forward(),
                onTapUp: (_) => _animationController.reverse(),
                onTapCancel: () => _animationController.reverse(),
                child: Center(
                  child: Icon(
                    widget.icon,
                    color: AppColors.textOnPrimary,
                    size: widget.mini ? AppConstants.iconS : AppConstants.iconM,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class CustomIconButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final double iconSize;

  const CustomIconButton({
    super.key,
    this.onPressed,
    required this.icon,
    this.tooltip,
    this.backgroundColor,
    this.iconColor,
    this.size = 48.0,
    this.iconSize = 24.0,
  });

  @override
  State<CustomIconButton> createState() => _CustomIconButtonState();
}

class _CustomIconButtonState extends State<CustomIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppConstants.animationFast,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.backgroundColor ?? AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                onTap: widget.onPressed,
                onTapDown: (_) => _animationController.forward(),
                onTapUp: (_) => _animationController.reverse(),
                onTapCancel: () => _animationController.reverse(),
                child: Center(
                  child: Icon(
                    widget.icon,
                    color: widget.iconColor ?? AppColors.textSecondary,
                    size: widget.iconSize,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ButtonConfig {
  final Color backgroundColor;
  final Color textColor;
  final LinearGradient? gradient;
  final Color shadowColor;
  final double borderRadius;
  final double elevation;
  final Border? border;

  ButtonConfig({
    required this.backgroundColor,
    required this.textColor,
    this.gradient,
    required this.shadowColor,
    required this.borderRadius,
    required this.elevation,
    this.border,
  });
}