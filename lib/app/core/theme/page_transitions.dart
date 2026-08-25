import 'package:flutter/material.dart';

/// Transición fluida estilo iOS/Material 3 con deslizamiento y opacidad simultánea
class SlideFadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final AxisDirection direction;

  SlideFadePageRoute({
    required this.page,
    this.direction = AxisDirection.left,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 280),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            Offset begin;
            switch (direction) {
              case AxisDirection.left:
                begin = const Offset(1.0, 0.0);
                break;
              case AxisDirection.right:
                begin = const Offset(-1.0, 0.0);
                break;
              case AxisDirection.up:
                begin = const Offset(0.0, 1.0);
                break;
              case AxisDirection.down:
                begin = const Offset(0.0, -1.0);
                break;
            }

            const end = Offset.zero;
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            final slideAnimation = Tween<Offset>(begin: begin, end: end).animate(curvedAnimation);
            final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation);

            return SlideTransition(
              position: slideAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            );
          },
        );
}

/// Transición con escalado suave (Zoom/Scale)
class ScaleFadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  ScaleFadePageRoute({
    required this.page,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
              reverseCurve: Curves.easeInCubic,
            );

            return ScaleTransition(
              scale: Tween<double>(begin: 0.90, end: 1.0).animate(curvedAnimation),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
                child: child,
              ),
            );
          },
        );
}

/// Transición de Desvanecimiento Puro (Fade Dissolve)
class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadePageRoute({
    required this.page,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
              child: child,
            );
          },
        );
}

/// Extensiones limpias para navegación animada con 1 línea de código
extension NavigationExtension on BuildContext {
  /// Deslizamiento horizontal estándar
  Future<T?> pushAnimated<T>(Widget page, {AxisDirection direction = AxisDirection.left}) {
    return Navigator.of(this).push<T>(
      SlideFadePageRoute(page: page, direction: direction),
    );
  }

  /// Reemplaza la pantalla actual con animación
  Future<T?> pushReplacementAnimated<T, TO>(Widget page, {AxisDirection direction = AxisDirection.left}) {
    return Navigator.of(this).pushReplacement<T, TO>(
      SlideFadePageRoute(page: page, direction: direction),
    );
  }

  /// Deslizamiento de abajo hacia arriba (Modal / Navegación)
  Future<T?> pushSlideUp<T>(Widget page) {
    return Navigator.of(this).push<T>(
      SlideFadePageRoute(page: page, direction: AxisDirection.up),
    );
  }

  /// Escalado Zoom & Fade
  Future<T?> pushScaleAnimated<T>(Widget page) {
    return Navigator.of(this).push<T>(
      ScaleFadePageRoute(page: page),
    );
  }

  /// Disolución suave (Fade)
  Future<T?> pushFade<T>(Widget page) {
    return Navigator.of(this).push<T>(
      FadePageRoute(page: page),
    );
  }
}
