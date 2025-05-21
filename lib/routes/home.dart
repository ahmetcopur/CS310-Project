import 'package:flutter/material.dart';
import 'package:su_credit/utils/colors.dart';
import 'package:provider/provider.dart';
import 'package:su_credit/providers/auth_provider.dart' as app_auth;
import 'package:su_credit/providers/user_course_data_provider.dart';
import 'add_given_courses.dart';
import 'package:su_credit/routes/schedule.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class Home extends StatefulWidget {
  final String userName;
  const Home({super.key, required this.userName});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late StreamSubscription<User?> _authSubscription;
  bool _isLoading = true;
  Map<String, dynamic>? _userProfile;
  List<Map<String, dynamic>> _todayClasses = [];
  List<Map<String, dynamic>> _tomorrowClasses = [];
  late final app_auth.AuthProvider _authProvider;
  late VoidCallback _scheduleListener;
  late VoidCallback _primaryListener;

  @override
  void initState() {
    super.initState();
    // Listen to schedule changes to refresh classes
    _scheduleListener = () => _loadUserData();
    savedSchedules.addListener(_scheduleListener);
    _primaryListener = () => _loadUserData();
    primaryScheduleIndex.addListener(_primaryListener);
    // Reload schedules on auth changes
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      loadSchedulesForCurrentUser();
    });
    // Initial load of schedules and user data
    loadSchedulesForCurrentUser();
    _loadUserData();
    // Initialize providers here to avoid async context issues
    _authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load user profile
      final userProfile = await _authProvider.getUserProfile();

      // Simulate whitespace delay
      await Future.delayed(Duration(milliseconds: 300));

      // Load today's and tomorrow's classes (simulated)
      final todayClasses = await _getClassesForDay(DateTime.now());
      final tomorrowClasses = await _getClassesForDay(DateTime.now().add(Duration(days: 1)));

      if (mounted) {
        setState(() {
          _userProfile = userProfile;
          _todayClasses = todayClasses;
          _tomorrowClasses = tomorrowClasses;
          _isLoading = false;
        });
      }
    } catch (e) {
      // On error, use default values
      if (mounted) {
        setState(() {
          // Use placeholder data
          _todayClasses = [
            {'code': 'CS310-0', 'time': '9:40-10.30', 'room': 'FASS G062'},
            {'code': 'PSY340-0', 'time': '14.40-15.30', 'room': 'FASS G049'},
          ];
          _tomorrowClasses = [
            {'code': 'CS408-0', 'time': '11:40-13.30', 'room': 'FENS L045'},
            {'code': 'CS307-0', 'time': '13.40-14.30', 'room': 'FENS G077'},
            {'code': 'CS310-0', 'time': '14.40-16.30', 'room': 'FASS G062'},
          ];
          _isLoading = false;
        });
      }
    }
  }

  // This would be implemented to fetch from Firestore in a real app
  Future<List<Map<String, dynamic>>> _getClassesForDay(DateTime date) async {
    // simulate brief delay
    await Future.delayed(const Duration(milliseconds: 200));
    // get primary schedule index and schedules
    final int? primaryIndex = primaryScheduleIndex.value;
    if (primaryIndex == null || primaryIndex < 0 || primaryIndex >= savedSchedules.value.length) {
      return [];
    }
    final schedule = savedSchedules.value[primaryIndex];
    // map weekday (Mon=1) to Day enum index
    final dayIdx = date.weekday - 1;
    if (dayIdx < 0 || dayIdx >= Day.values.length) return [];
    final targetDay = Day.values[dayIdx];
    // collect all meetings on this day
    final classes = <Map<String, dynamic>>[];
    for (var course in schedule) {
      for (var meeting in course.meetings) {
        if (meeting.day == targetDay) {
          classes.add({
            'code': course.code,
            'time': '${meeting.start}:00-${meeting.end}:00',
            'room': meeting.location ?? '',
            'start': meeting.start,
          });
        }
      }
    }
    // sort by start hour
    classes.sort((a, b) => (a['start'] as int).compareTo(b['start'] as int));
    // remove helper 'start' key
    return classes.map((c) {
      c.remove('start');
      return c;
    }).toList();
  }

  @override
  void dispose() {
    savedSchedules.removeListener(_scheduleListener);
    primaryScheduleIndex.removeListener(_primaryListener);
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: _isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: AppColors.surface, strokeWidth: 2))
            : Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddGivenCoursesPage(),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(
                        _userProfile?['profileImage'] ?? 'https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _userProfile?['name'] ?? widget.userName,
                        style: const TextStyle(
                          color: AppColors.surface,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _userProfile?['faculty'] ?? 'Faculty of Engineering and Natural Sciences',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
        actions: [
          TextButton(
            onPressed: () async {
              // Use auth provider for logout
              final userCourseProvider = Provider.of<UserCourseDataProvider>(context, listen: false);
              userCourseProvider.clear(); // Clear user-specific data on logout
              await _authProvider.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text(
              'Logout',
              style: TextStyle(
                color: AppColors.surface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30), // add spacing if needed after removal

            // Padding for Ongoing Program
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 25,
                vertical: 30,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ongoing Program',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.lightBlue[300],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Divider(
                    color: Colors.lightBlue[300],
                    thickness: 2,
                    height: 1,
                  ),
                ],
              ),
            ),

            // Today's Schedule
            _scheduleSection(
              title: "Today's Program:",
              classes: _todayClasses,
            ),

            const SizedBox(height: 30),

            // Tomorrow's Schedule
            _scheduleSection(
              title: "Tomorrow's Program:",
              classes: _tomorrowClasses,
            ),

            const SizedBox(height: 40),

            Container(
              width: double.infinity,
              color: AppColors.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: 25,
                vertical: 80,
              ),
              child: Column(
                children: [
                  HomeMenuButton(
                    label: 'Student Dashboard',
                    backgroundColor: const Color(0xFF3BA3DA),
                    onTap: () {
                      Navigator.pushNamed(context, '/dashboard');
                    },
                  ),
                  const SizedBox(height: 16),
                  HomeMenuButton(
                    label: 'Course Planning',
                    backgroundColor: const Color(0xFF6AD5B0),
                    onTap: () {
                      Navigator.pushNamed(context, '/course_planning');
                    },
                  ),
                  const SizedBox(height: 16),
                  HomeMenuButton(
                    label: 'GPA Tracker',
                    backgroundColor: const Color(0xFFF9D24F),
                    onTap: () {
                      Navigator.pushNamed(context, '/gpa_tracker');
                    },
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scheduleSection({required String title, required List<Map<String, dynamic>> classes}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.heading,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: classes.isEmpty
                ? [const Text('No classes scheduled', style: TextStyle(fontSize: 16))]
                : classes.map((classInfo) {
              return BulletText('${classInfo['code']} at ${classInfo['time']} (${classInfo['room']})');
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// Existing BulletText class - keep this as is
class BulletText extends StatelessWidget {
  final String text;
  const BulletText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Existing HomeMenuButton class - keep this as is
class HomeMenuButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final VoidCallback onTap;

  const HomeMenuButton({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        width: double.infinity,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.surface,
            ),
          ),
        ),
      ),
    );
  }
}