
import 'package:flutter/material.dart';

class AppColors {
  static Color textColor(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium!.color!;

  static Color bgColor(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;
}
