import 'package:flutter/material.dart';

bool harborReducesMotion(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context);

Duration harborMotionDuration(BuildContext context, Duration duration) =>
    harborReducesMotion(context) ? Duration.zero : duration;

AnimationStyle? harborAnimationStyle(BuildContext context) =>
    harborReducesMotion(context) ? AnimationStyle.noAnimation : null;

Future<T?> showHarborDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) => showDialog<T>(
  context: context,
  builder: builder,
  barrierDismissible: barrierDismissible,
  animationStyle: harborAnimationStyle(context),
);

void showHarborSnackBar(BuildContext context, SnackBar snackBar) {
  ScaffoldMessenger.of(context).showSnackBar(
    snackBar,
    snackBarAnimationStyle: harborAnimationStyle(context),
  );
}

final class HarborPageTransitionsBuilder extends PageTransitionsBuilder {
  const HarborPageTransitionsBuilder(this.delegate);

  final PageTransitionsBuilder delegate;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (harborReducesMotion(context)) return child;
    return delegate.buildTransitions(
      route,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}
