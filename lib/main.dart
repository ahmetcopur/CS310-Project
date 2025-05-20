import 'package:flutter/material.dart';
import 'package:su_credit/routes/dashboard.dart';
import 'package:su_credit/routes/login.dart';
import 'package:su_credit/routes/home.dart';
import 'package:su_credit/routes/assignments.dart';
import 'package:su_credit/routes/gpa_tracker.dart';
import 'package:su_credit/routes/search_course.dart';
import 'package:su_credit/routes/course_info.dart';
import 'package:su_credit/routes/course_planning.dart';
import 'package:su_credit/routes/schedule.dart';
import 'package:su_credit/routes/graduation_progress.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:su_credit/routes/register.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// Fix provider import path
import 'package:su_credit/providers/course_provider.dart';
// Import providers with aliasing to avoid conflicts
import 'package:su_credit/providers/auth_provider.dart' as app_auth;
import 'package:su_credit/providers/course_provider.dart';
import 'package:su_credit/providers/assignment_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Wrap MaterialApp with MultiProvider
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => app_auth.AuthProvider()),
        ChangeNotifierProvider(create: (_) => CourseProvider()),
        ChangeNotifierProvider(create: (_) => AssignmentProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SuCredit',
        onGenerateRoute: (RouteSettings settings) {
          final user = FirebaseAuth.instance.currentUser;
          Widget page;
          switch (settings.name) {
            case '/login':
              page = (user != null)
                  ? Home(userName: user.email ?? '')
                  : const Login();
              break;
            case '/register':
              page = (user != null)
                  ? Home(userName: user.email ?? '')
                  : const Register();
              break;
            case '/home':
              page = (user != null)
                  ? Home(userName: user.email ?? '')
                  : const Login();
              break;
            case '/dashboard':
              page = (user != null)
                  ? const StudentDashboard()
                  : const Login();
              break;
            case '/assignments':
              page = (user != null)
                  ? const AssignmentsPage()
                  : const Login();
              break;
            case '/gpa_tracker':
              page = (user != null)
                  ? const GpaTrackerPage()
                  : const Login();
              break;
            case '/course_planning':
              page = (user != null)
                  ? const CoursePlanningPage()
                  : const Login();
              break;
            case '/course_info':
              page = (user != null)
                  ? const CourseDetailPage(courseName: '')
                  : const Login();
              break;
            case '/search_courses':
              page = (user != null)
                  ? const SearchCoursesPage()
                  : const Login();
              break;
            case '/schedule':
              page = (user != null)
                  ? const SchedulePage(index: 0)
                  : const Login();
              break;
            case '/graduation_progress':
              page = (user != null)
                  ? const GraduationProgressPage()
                  : const Login();
              break;
            default:
              page = const Login();
          }
          return MaterialPageRoute(builder: (_) => page, settings: settings);
        },
      ),
    );
  }
}