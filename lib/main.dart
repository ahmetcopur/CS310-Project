import 'package:flutter/material.dart';
import 'package:su_credit/routes/login.dart';
import 'package:su_credit/routes/home.dart';
/*
import 'package:su_credit/routes/dashboard.dart';
import 'package:su_credit/routes/course_planning.dart';
import 'package:su_credit/routes/gpa_tracker.dart';
import 'package:su_credit/routes/schedule.dart';
import 'package:su_credit/routes/search_course.dart';
import 'package:su_credit/routes/course_info.dart';
import 'package:su_credit/routes/assignments.dart';
import 'package:su_credit/routes/graduation_progress.dart';
*/

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
      // Define only the login route in the routes map
      initialRoute: "/login",
      routes: {
        "/login": (context) => const Login(),
        // Don't include routes that need parameters in the routes map
      },
      // Use onGenerateRoute for routes that need parameters
      onGenerateRoute: (settings) {
        if (settings.name == '/home') {
          // Extract the username from arguments
          final args = settings.arguments as Map<String, dynamic>;
          final userName = args['userName'] as String;

          return MaterialPageRoute(
            builder: (context) => Home(userName: userName),
          );
        }
        return null;
      },
    );
  }
}