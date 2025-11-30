import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double elevation;
  final VoidCallback? onTap;
  final Border? border;
  final Gradient? gradient;

  const CustomCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 16,
    this.elevation = 4,
    this.onTap,
    this.border,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor ?? Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(borderRadius),
            border: border,
            gradient: gradient,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: elevation * 2,
                spreadRadius: elevation / 2,
                offset: Offset(0, elevation),
              ),
            ],
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}