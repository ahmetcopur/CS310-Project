import 'package:flutter/material.dart';
import 'package:su_credit/routes/login.dart';
import 'package:su_credit/routes/home.dart';
import 'package:su_credit/routes/dashboard.dart';
import 'package:su_credit/routes/course_planning.dart';
import 'package:su_credit/routes/gpa_tracker.dart';
import 'package:su_credit/routes/schedule.dart';
import 'package:su_credit/routes/search_course.dart';
import 'package:su_credit/routes/course_info.dart';
import 'package:su_credit/routes/assignments.dart';
import 'package:su_credit/routes/graduation_progress.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SuCredit',
      initialRoute: "/login",
      routes: {
        "/login":(context)=>LoginPage(),
        "/home":(context)=>HomePage(),
        "/dashboard":(context)=>Dashboard(),
        "/course_planning":(context)=>CoursePlan(),
        "/gpa_tracker":(context)=>GpaTracker(),
        "/schedule":(context)=>Schedule(),
        "/search_course":(context)=>SearchCourse(),
        "/course_info":(context)=>CourseInfo(),
        "/assignments":(context)=>Assignments(),
        "/graduation_progress":(context)=>GraduationProgress(),
      },
    );
  }
}