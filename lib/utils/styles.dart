import 'package:flutter/material.dart';
import 'colors.dart';
import 'dimensions.dart';

class AppStyles {
  static final TextStyle screenTitle = TextStyle(
    fontFamily: 'Roboto',
    fontSize: AppDimensions.fontSizeExtraLarge,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static final TextStyle sectionHeading = TextStyle(
    fontSize: AppDimensions.fontSizeLarge,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static final TextStyle subHeading = TextStyle(
    fontSize: AppDimensions.fontSizeMedium,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static final TextStyle bodyText = TextStyle(
    fontSize: AppDimensions.fontSizeMedium,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static final TextStyle bodyTextSecondary = TextStyle(
    fontSize: AppDimensions.fontSizeSmall,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  static final TextStyle warningText = TextStyle(
    fontSize: AppDimensions.fontSizeMedium,
    fontWeight: FontWeight.bold,
    color: AppColors.warning,
  );

  static final TextStyle buttonText = TextStyle(
    fontSize: AppDimensions.fontSizeMedium,
    fontWeight: FontWeight.w600,
    color: AppColors.surface,
  );

  static final TextStyle errorText = TextStyle(
    fontSize: AppDimensions.fontSizeSmall,
    fontWeight: FontWeight.w500,
    color: AppColors.error,
  );
}