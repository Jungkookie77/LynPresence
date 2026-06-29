import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';

class OrganicBackground extends StatelessWidget {
  final Widget child;

  const OrganicBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base color
        const SizedBox.expand(
          child: DecoratedBox(
            decoration: BoxDecoration(color: AppColors.background),
          ),
        ),
        
        // Blob 1 (Top Left)
        Positioned(
          top: -100,
          left: -150,
          child: RepaintBoundary(
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFB347).withOpacity(0.15),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFB347).withOpacity(0.15),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
             .scaleXY(begin: 0.9, end: 1.1, duration: 6.seconds, curve: Curves.easeInOut)
             .moveX(begin: -20, end: 20, duration: 8.seconds),
          ),
        ),

        // Blob 2 (Bottom Right)
        Positioned(
          bottom: -150,
          right: -100,
          child: RepaintBoundary(
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF66B2).withOpacity(0.1),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF66B2).withOpacity(0.1),
                    blurRadius: 120,
                    spreadRadius: 60,
                  ),
                ],
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
             .scaleXY(begin: 0.8, end: 1.2, duration: 7.seconds, curve: Curves.easeInOut)
             .moveY(begin: -30, end: 30, duration: 9.seconds),
          ),
        ),

        // Blob 3 (Center Right)
        Positioned(
          top: 200,
          right: -50,
          child: RepaintBoundary(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: const Color(0xFF66C2FF).withOpacity(0.15),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF66C2FF).withOpacity(0.15),
                    blurRadius: 80,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
             .moveX(begin: 0, end: -40, duration: 5.seconds, curve: Curves.easeInOut),
          ),
        ),

        // Foreground content
        Positioned.fill(child: child),
      ],
    );
  }
}
