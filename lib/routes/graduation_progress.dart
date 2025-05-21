import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:su_credit/utils/colors.dart';
import 'package:su_credit/utils/dimensions.dart';
import 'package:su_credit/utils/styles.dart';
// import 'package:firebase_auth/firebase_auth.dart'; // Not directly used for logic in this version
// import 'package:cloud_firestore/cloud_firestore.dart'; // Not directly used for logic in this version
// import 'package:su_credit/models/course.dart'; // Assumed to be used by _getCourseDetails
// Used
import 'package:provider/provider.dart';
import 'package:su_credit/providers/user_course_data_provider.dart';

// --- Placeholder for actual Course Details ---
// In a real app, this data (especially 'type') would come from your Course model/provider
class _CourseDetails {
final int credits;
final String type; // NOW: "core", "area", "free"
final String id;

_CourseDetails({required this.id, required this.credits, required this.type});
}

// --- SIMULATED Course Database ---
// TODO: Replace this with your actual course data source and ensure types match "core", "area", "free"
Map<String, _CourseDetails> _sampleCourseDatabase = {
'CS101': _CourseDetails(id: 'CS101', credits: 3, type: 'core'),
'MA101': _CourseDetails(id: 'MA101', credits: 4, type: 'core'),
'CS307': _CourseDetails(id: 'CS307', credits: 3, type: 'core'), // Example Core
'CS401': _CourseDetails(id: 'CS401', credits: 3, type: 'area'), // Example Area
'HUM202': _CourseDetails(id: 'HUM202', credits: 3, type: 'area'),// Example Area
'ART101': _CourseDetails(id: 'ART101', credits: 3, type: 'free'), // Example Free
'SPS303': _CourseDetails(id: 'SPS303', credits: 3, type: 'free'), // Example Free
// Courses previously 'university_required' would now be one of the above.
// For example, ENG101 might be 'core' or a specific requirement you check by ID.
'ENG101': _CourseDetails(id: 'ENG101', credits: 3, type: 'core'),
'NS101': _CourseDetails(id: 'NS101', credits: 4, type: 'core'),
// Add more sample courses as needed for testing the 49-credit structure
};

_CourseDetails _getCourseDetailsSimulated(String courseId) {
final upperCourseId = courseId.toUpperCase();
return _sampleCourseDatabase[upperCourseId] ??
_CourseDetails(id: courseId, credits: 3, type: 'free'); // Default for unknown
}
// --- End of Placeholder Data ---

class GraduationProgressPage extends StatefulWidget {
const GraduationProgressPage({super.key});

@override
State<GraduationProgressPage> createState() => _GraduationProgressPageState();
}

class _GraduationProgressPageState extends State<GraduationProgressPage> {

@override
void initState() {
super.initState();
// Data loading is handled by the provider
}

@override
Widget build(BuildContext context) {
final userCourseProvider = Provider.of<UserCourseDataProvider>(context);
final completedUserCourseEntries = userCourseProvider.entries.where((e) => e.isCompleted).toList();
final bool isLoading = userCourseProvider.isLoading;

// --- Define Program Requirements (based on StudentDashboard) ---
const int requiredTotalCreditsTarget = 49;
const int requiredCoreCreditsTarget = 31;
const int requiredAreaCreditsTarget = 9;
const int requiredFreeCreditsTarget = 9;

// --- Calculate Earned Credits By Type ---
int earnedCoreCredits = 0;
int earnedAreaCredits = 0;
int earnedFreeCredits = 0;
int totalEarnedCreditsValue = 0;
// List<String> completedCourseIds = []; // Keep if needed for specific course checks

for (final entry in completedUserCourseEntries) {
final courseDetails = _getCourseDetailsSimulated(entry.courseId);
totalEarnedCreditsValue += courseDetails.credits;
// completedCourseIds.add(entry.courseId.toUpperCase());

switch (courseDetails.type) {
case 'core':
earnedCoreCredits += courseDetails.credits;
break;
case 'area':
earnedAreaCredits += courseDetails.credits;
break;
case 'free':
earnedFreeCredits += courseDetails.credits;
break;
// No 'university_required' distinct category for this 49-credit model
}
}
int remainingCreditsToTarget = (requiredTotalCreditsTarget - totalEarnedCreditsValue).clamp(0, requiredTotalCreditsTarget);


// --- Prepare Pie Chart Data ---
// Colors from StudentDashboard _CreditChip:
// Area: AppColors.accentBlue
// Core: AppColors.accentTeal
// Free: AppColors.accentPink
// Total: AppColors.accentOrange (used for overall progress, not a pie slice type here)

final pieSections = [
if (earnedCoreCredits > 0)
PieChartSectionData(value: earnedCoreCredits.toDouble(), color: AppColors.accentTeal, title: '$earnedCoreCredits\nCore', radius: 50, titleStyle: AppStyles.bodyText.copyWith(fontSize:10, color: AppColors.surface, fontWeight: FontWeight.bold)),
if (earnedAreaCredits > 0)
PieChartSectionData(value: earnedAreaCredits.toDouble(), color: AppColors.accentBlue, title: '$earnedAreaCredits\nArea', radius: 50, titleStyle: AppStyles.bodyText.copyWith(fontSize:10, color: AppColors.surface, fontWeight: FontWeight.bold)),
if (earnedFreeCredits > 0)
PieChartSectionData(value: earnedFreeCredits.toDouble(), color: AppColors.accentPink, title: '$earnedFreeCredits\nFree', radius: 50, titleStyle: AppStyles.bodyText.copyWith(fontSize:10, color: AppColors.surface, fontWeight: FontWeight.bold)),
if (remainingCreditsToTarget > 0)
PieChartSectionData(value: remainingCreditsToTarget.toDouble(), color: AppColors.textTertiary.withOpacity(0.3), title: '$remainingCreditsToTarget\nRemain', radius: 50, titleStyle: AppStyles.bodyText.copyWith(fontSize:10, color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
];
if (pieSections.isEmpty && totalEarnedCreditsValue == 0 && remainingCreditsToTarget > 0) {
pieSections.add(PieChartSectionData(
value: remainingCreditsToTarget.toDouble(),
color: AppColors.textTertiary.withOpacity(0.3), // A neutral "empty" color
title: '$remainingCreditsToTarget\nTo Go',
radius: 50,
titleStyle: AppStyles.bodyText.copyWith(fontSize:10, color: AppColors.textPrimary)
));
}


// --- Determine Status Message ---
String statusMessage;
double progressPercentage = (requiredTotalCreditsTarget > 0) ? (totalEarnedCreditsValue / requiredTotalCreditsTarget.toDouble()) : 0.0;

if (totalEarnedCreditsValue >= requiredTotalCreditsTarget) {
statusMessage = "All credit requirements appear to be met!";
} else if (progressPercentage >= 0.75) {
statusMessage = "Great progress! Almost there.";
} else if (progressPercentage >= 0.5) {
statusMessage = "Good job! Over halfway to completion.";
} else if (progressPercentage >= 0.25) {
statusMessage = "Making steady progress.";
} else if (totalEarnedCreditsValue > 0) {
statusMessage = "You've started! Keep it up.";
}
else {
statusMessage = "Begin your academic journey by completing courses!";
}

// --- Prepare Notification Items ---
List<Widget> notificationItems = [];

int neededCore = (requiredCoreCreditsTarget - earnedCoreCredits).clamp(0, requiredCoreCreditsTarget);
if (neededCore > 0) {
notificationItems.add(_bullet('$neededCore more Core Credits (target: $requiredCoreCreditsTarget)', AppColors.accentTeal));
}

int neededArea = (requiredAreaCreditsTarget - earnedAreaCredits).clamp(0, requiredAreaCreditsTarget);
if (neededArea > 0) {
notificationItems.add(_bullet('$neededArea more Area Credits (target: $requiredAreaCreditsTarget)', AppColors.accentBlue));
}

int neededFree = (requiredFreeCreditsTarget - earnedFreeCredits).clamp(0, requiredFreeCreditsTarget);
if (neededFree > 0) {
notificationItems.add(_bullet('$neededFree more Free Credits (target: $requiredFreeCreditsTarget)', AppColors.accentPink));
}

if (notificationItems.isEmpty && totalEarnedCreditsValue >= requiredTotalCreditsTarget) {
notificationItems.add(
Padding(
padding: const EdgeInsets.symmetric(vertical: 8.0),
child: Text(
"Congratulations! All credit requirements appear to be met based on the 49-credit program structure. Please consult your advisor for final graduation clearance.",
style: AppStyles.bodyText.copyWith(color: AppColors.accentBlue, fontWeight: FontWeight.bold),
),
));
} else if (notificationItems.isEmpty && totalEarnedCreditsValue < requiredTotalCreditsTarget) {
// This case might occur if all categories are met but total is not (due to rounding or complex rules not captured)
// Or if all categories individually are met but the total is still short.
// For this simplified model, if categories are met, total should be met.
notificationItems.add(
Padding(
padding: const EdgeInsets.symmetric(vertical: 8.0),
child: Text(
"You are close! Ensure all categories add up to the total of $requiredTotalCreditsTarget credits.",
style: AppStyles.bodyText.copyWith(color: AppColors.textPrimary),
),
)
);
}


return Scaffold(
backgroundColor: AppColors.backgroundColor,
appBar: AppBar(
backgroundColor: AppColors.primary,
leading: IconButton(
icon: const Icon(Icons.arrow_back, color: AppColors.surface),
onPressed: () { Navigator.pop(context); },
),
title: Text('Graduation Progress',
style: AppStyles.screenTitle.copyWith(color: AppColors.surface)),
),
body: isLoading
? const Center(child: CircularProgressIndicator())
    : SingleChildScrollView(
padding: AppDimensions.regularParentPadding,
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
_card(
child: Column(
children: [
SizedBox(
height: 230, // Adjusted height
child: Stack(
alignment: Alignment.center,
children: [
if (pieSections.isNotEmpty)
PieChart(
PieChartData(
sections: pieSections,
sectionsSpace: 2,
centerSpaceRadius: 75,
startDegreeOffset: -90,
pieTouchData: PieTouchData(
touchCallback: (FlTouchEvent event, pieTouchResponse) {
// Handle touch events if needed
},
),
),
) else Center(child: Text("No credit data to display.", style: AppStyles.bodyTextSecondary)),
Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Text(
'$totalEarnedCreditsValue',
style: AppStyles.screenTitle.copyWith(fontSize: 40, color: AppColors.primary),
),
Text(
'/ $requiredTotalCreditsTarget Credits',
textAlign: TextAlign.center,
style: AppStyles.bodyText.copyWith(
color: AppColors.textPrimary,
fontSize: 16,
fontWeight: FontWeight.bold),
),
],
),
],
),
),
// Legend
AppDimensions.verticalSpace(AppDimensions.paddingMedium),
if(pieSections.isNotEmpty && !(pieSections.length == 1 && pieSections.first.title.contains("To Go")))
_buildLegend([
if(earnedCoreCredits > 0) MapEntry('Core Credits ($earnedCoreCredits/$requiredCoreCreditsTarget)', AppColors.accentTeal),
if(earnedAreaCredits > 0) MapEntry('Area Credits ($earnedAreaCredits/$requiredAreaCreditsTarget)', AppColors.accentBlue),
if(earnedFreeCredits > 0) MapEntry('Free Credits ($earnedFreeCredits/$requiredFreeCreditsTarget)', AppColors.accentPink),
if(remainingCreditsToTarget > 0) MapEntry('Remaining ($remainingCreditsToTarget)', AppColors.textTertiary.withOpacity(0.3)),
]),
],
),
),
AppDimensions.verticalSpace(AppDimensions.paddingLarge),
Text('Status & Requirements',
style: AppStyles.sectionHeading
    .copyWith(color: AppColors.primary, fontSize: 20)),
AppDimensions.verticalSpace(AppDimensions.paddingSmall),
_card(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(statusMessage,
style: AppStyles.sectionHeading
    .copyWith(fontSize: 18, color: AppColors.primary, fontWeight: FontWeight.w600)),
AppDimensions.verticalSpace(AppDimensions.paddingSmall),
if (notificationItems.isNotEmpty) const Divider(),
...notificationItems,
if (notificationItems.isEmpty && totalEarnedCreditsValue < requiredTotalCreditsTarget)
Padding(
padding: const EdgeInsets.symmetric(vertical: 8.0),
child: Text("All categories seem met, but ensure total credits reach $requiredTotalCreditsTarget.", style: AppStyles.bodyText),
),
],
),
),
AppDimensions.verticalSpace(AppDimensions.paddingLarge),
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
boxShadow: [
BoxShadow(
color: Colors.grey.withOpacity(0.15),
spreadRadius: 1,
blurRadius: 5,
offset: const Offset(0, 2),
)
]
),
padding: const EdgeInsets.all(16),
child: child,
);

Widget _buildLegend(List<MapEntry<String, Color>> legendData) {
return Wrap(
spacing: AppDimensions.paddingLarge, // Increased spacing for fewer items
runSpacing: AppDimensions.paddingSmall,
alignment: WrapAlignment.center,
children: legendData.map((entry) {
return Row(
mainAxisSize: MainAxisSize.min,
children: [
Container(width: 14, height: 14, color: entry.value), // Slightly larger legend color box
const SizedBox(width: 8),
Text(entry.key, style: AppStyles.bodyTextSecondary.copyWith(fontSize: 13)), // Slightly larger legend text
],
);
}).toList(),
);
}

Widget _bullet(String text, Color c, {bool isBold = false}) => Padding(
padding: const EdgeInsets.symmetric(vertical: 6),
child: Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Container(
margin: const EdgeInsets.only(top: 5),
width: 9, height: 9, decoration: BoxDecoration(color: c, shape: BoxShape.circle)), // Slightly larger bullet
const SizedBox(width: 10),
Expanded(child: Text(text, style: AppStyles.bodyText.copyWith(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, height: 1.4, fontSize: 14.5))), // Slightly larger text
],
),
);
}