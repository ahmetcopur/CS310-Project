import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:su_credit/utils/colors.dart';
import 'package:su_credit/utils/dimensions.dart';
import 'package:su_credit/utils/styles.dart';

class GraduationProgressPage extends StatelessWidget {
  const GraduationProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    const requiredTotal = 125;
    const earned = 75;
    const minJunior = 64;
    const maxSenior = 94;

    final pieSections = [
      PieChartSectionData(value: 50, color: AppColors.accentOrange, title: ''),
      PieChartSectionData(value: 20, color: AppColors.accentTeal, title: ''),
      PieChartSectionData(value: 15, color: AppColors.accentBlue, title: ''),
      PieChartSectionData(value: 15, color: AppColors.accentPink, title: ''),
      PieChartSectionData(value: 25, color: AppColors.backgroundColor, title: ''),
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.surface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Graduation Progress',
            style: AppStyles.screenTitle.copyWith(color: AppColors.surface)),
      ),
      body: SingleChildScrollView(
        padding: AppDimensions.regularParentPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _card(
              child: SizedBox(
                height: 280,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sections: pieSections,
                        sectionsSpace: 2,
                        centerSpaceRadius: 60,
                        startDegreeOffset: -90,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$earned/$requiredTotal SU\nCredits Earned',
                        textAlign: TextAlign.center,
                        style: AppStyles.bodyText.copyWith(
                            color: AppColors.surface,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    _pieLabel('Free\nCredits', AppColors.accentPink,
                        const Offset(-130, -35)),
                    _pieLabel('Area\nCredits', AppColors.accentBlue,
                        const Offset(-96, 48)),
                    _pieLabel('Core\nCredits', AppColors.accentTeal,
                        const Offset(10, 85)),
                    _pieLabel('Required\nCredits', AppColors.accentOrange,
                        const Offset(110, -105)),
                  ],
                ),
              ),
            ),
            AppDimensions.verticalSpace(AppDimensions.paddingLarge),
            Text('Recommended SU Credits',
                style: AppStyles.sectionHeading
                    .copyWith(color: AppColors.primary, fontSize: 20)),
            AppDimensions.verticalSpace(AppDimensions.paddingSmall),
            _card(
              color: AppColors.primary,
              child: Column(
                children: [
                  Row(
                    children: [
                      _circle('$minJunior', size: 56, textSize: 18),
                      Expanded(child: Container(height: 5, color: AppColors.surface)),
                      _circle('$maxSenior', size: 56, textSize: 18),
                    ],
                  ),
                  SizedBox(
                    height: 60,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          left: ((earned - minJunior) /
                              (maxSenior - minJunior))
                              .clamp(0, 1) *
                              MediaQuery.of(context).size.width,
                          child: Column(
                            children: [
                              const Icon(Icons.arrow_drop_up,
                                  size: 40, color: Colors.redAccent),
                              Text('$earned',
                                  style: AppStyles.bodyText.copyWith(
                                      color: AppColors.surface,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Junior',
                          style: AppStyles.bodyText.copyWith(
                              color: AppColors.surface,
                              fontWeight: FontWeight.w600)),
                      Text('Senior',
                          style: AppStyles.bodyText.copyWith(
                              color: AppColors.surface,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Divider(color: AppColors.text, thickness: 1),
                  const SizedBox(height: 6),
                  Text('"Able to finish on time"',
                      style: AppStyles.bodyText.copyWith(
                          color: AppColors.surface,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ],
              ),
            ),
            AppDimensions.verticalSpace(AppDimensions.paddingLarge),
            Text('Notifications',
                style: AppStyles.sectionHeading
                    .copyWith(color: AppColors.primary, fontSize: 20)),
            AppDimensions.verticalSpace(AppDimensions.paddingSmall),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('You need to get:',
                      style: AppStyles.bodyText
                          .copyWith(fontWeight: FontWeight.bold)),
                  AppDimensions.verticalSpace(AppDimensions.paddingSmall),
                  _bullet('CS 301, CS 395, ENS 491, ENS 492',
                      AppColors.accentOrange),
                  _bullet('More Core Credits', AppColors.accentTeal),
                  _bullet('More Area Credits', AppColors.secondary),
                  _bullet('More Free Credits', AppColors.accentPink),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child, Color? color}) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: color ?? AppColors.surface,
      borderRadius:
      BorderRadius.circular(AppDimensions.borderRadiusMedium),
    ),
    padding: const EdgeInsets.all(16),
    child: child,
  );

  Widget _circle(String txt, {double size = 48, double textSize = 16}) =>
      Container(
        width: size,
        height: size,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration:
        const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text(txt,
            style: AppStyles.bodyText.copyWith(
                color: AppColors.primary,
                fontSize: textSize,
                fontWeight: FontWeight.bold)),
      );

  Widget _bullet(String text, Color c) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Container(
            width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: AppStyles.bodyText)),
      ],
    ),
  );

  Widget _pieLabel(String txt, Color c, Offset off) => Positioned(
    left: 160 + off.dx,
    top: 160 + off.dy,
    child: Text(
      txt,
      textAlign: TextAlign.center,
      style: AppStyles.bodyText.copyWith(
          fontSize: 12, fontWeight: FontWeight.bold, color: c),
    ),
  );
}
