// lib/widgets/avatar_widget.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AvatarWidget extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double size;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const AvatarWidget({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 40,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = AppColors.accent;
    final bgColor = backgroundColor ?? defaultColor;
    
    final widget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor.withOpacity(0.1),
        gradient: imageUrl == null || imageUrl!.isEmpty
            ? LinearGradient(
                colors: [bgColor, bgColor.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? _buildNetworkImage()
            : Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: size * 0.4,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: widget,
      );
    }
    return widget;
  }

  Widget _buildNetworkImage() {
    final String fullUrl;
    if (imageUrl!.startsWith('http')) {
      fullUrl = imageUrl!;
    } else if (imageUrl!.startsWith('/uploads')) {
      fullUrl = 'http://localhost:5001$imageUrl';
    } else {
      fullUrl = imageUrl!;
    }

    return Image.network(
      fullUrl,
      fit: BoxFit.cover,
      width: size,
      height: size,
      errorBuilder: (context, error, stackTrace) {
        return Center(
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: TextStyle(
              fontSize: size * 0.4,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}