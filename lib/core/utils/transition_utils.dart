import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Static factory methods for consistent GoRouter page transitions.
class TransitionUtils {
  TransitionUtils._();

  /// Slides the new page in from the right (300 ms, [Curves.easeInOut]).
  static Page<T> slideFromRight<T>({
    required Widget child,
    required GoRouterState state,
  }) =>
      CustomTransitionPage<T>(
        key: state.pageKey,
        child: child,
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          final tween = Tween(begin: begin, end: end)
              .chain(CurveTween(curve: Curves.easeInOut));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      );

  /// Fades the new page in (200 ms, [Curves.easeIn]).
  static Page<T> fadeTransition<T>({
    required Widget child,
    required GoRouterState state,
  }) =>
      CustomTransitionPage<T>(
        key: state.pageKey,
        child: child,
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation.drive(CurveTween(curve: Curves.easeIn)),
            child: child,
          );
        },
      );

  /// Instant tab switch with no animation.
  static Page<T> noTransition<T>({
    required Widget child,
    required GoRouterState state,
  }) =>
      NoTransitionPage<T>(
        key: state.pageKey,
        child: child,
      );
}
