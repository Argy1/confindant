import 'package:confindant/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AppGradients {
  static const appBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.navy900, AppColors.blue900],
  );

  static const primaryAction = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.navy900, AppColors.blue900],
  );

  static const scanFab = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.blue900, AppColors.blue600],
  );
}
