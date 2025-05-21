import 'package:flutter/material.dart';
import 'package:su_credit/utils/colors.dart';
import 'package:su_credit/utils/styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Helper class for Day functionality
class _DayHelper {
  static Day fromString(String value) {
    return Day.values.firstWhere(
          (day) => day.toString().split('.').last == value,
      orElse: () => Day.mon,
    );
  }
}

// Keep the existing ValueNotifier for local state
// Using Course instead of _Course to avoid private type in public API
final ValueNotifier<List<Set<_Course>>> savedSchedules =
ValueNotifier<List<Set<_Course>>>([]);

// Track which schedule is primary (index)
final ValueNotifier<int?> primaryScheduleIndex = ValueNotifier<int?>(null);

/// Load saved schedules from Firestore into the global ValueNotifier
Future<void> loadSchedulesForCurrentUser() async {
  // Clear old schedules immediately on auth change
  savedSchedules.value = [];
  primaryScheduleIndex.value = null;
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) {
    savedSchedules.value = [];
    primaryScheduleIndex.value = null;
    return;
  }
  try {
    // Fetch user's schedules without composite index requirement, then sort locally by 'index'
    final querySnapshot = await FirebaseFirestore.instance
        .collection('schedules')
        .where('userId', isEqualTo: userId)
        .get();
    final docs = querySnapshot.docs.toList();
    docs.sort((a, b) {
      final aIndex = a.data()['index'] as int? ?? 0;
      final bIndex = b.data()['index'] as int? ?? 0;
      return aIndex.compareTo(bIndex);
    });
    final List<Set<_Course>> list = [];
    int? foundPrimary;
    for (final doc in docs) {
      final data = doc.data();
      final scheduleSet = <_Course>{};
      if (data['courses'] is List) {
        for (var courseData in data['courses']) {
          scheduleSet.add(_Course.fromFirestore(courseData));
        }
      }
      list.add(scheduleSet);
      // detect primary flag
      if (data['primary'] == true) {
        foundPrimary = data['index'] as int? ?? list.length - 1;
      }
    }
    savedSchedules.value = list;
    primaryScheduleIndex.value = foundPrimary;
  } catch (e) {
    debugPrint('Error loading schedules: $e');
    // Clear on error
    savedSchedules.value = [];
    primaryScheduleIndex.value = null;
  }
}

/// Set a schedule as primary: only one per user
Future<void> setPrimarySchedule(int index) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return;
  try {
    // Unset previous primary
    final prev = await FirebaseFirestore.instance
        .collection('schedules')
        .where('userId', isEqualTo: userId)
        .where('primary', isEqualTo: true)
        .get();
    for (var doc in prev.docs) {
      await doc.reference.update({'primary': false});
    }
    // Set new primary
    final target = await FirebaseFirestore.instance
        .collection('schedules')
        .where('userId', isEqualTo: userId)
        .where('index', isEqualTo: index)
        .limit(1)
        .get();
    if (target.docs.isNotEmpty) {
      await target.docs.first.reference.update({'primary': true});
      primaryScheduleIndex.value = index;
    }
  } catch (e) {
    debugPrint('Error setting primary schedule: $e');
  }
}

/// Delete a schedule by index, reindexing remaining schedules
Future<void> deleteSchedule(int index) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  // Update local state
  final list = List<Set<_Course>>.from(savedSchedules.value);
  if (index < 0 || index >= list.length) return;
  list.removeAt(index);
  savedSchedules.value = list;
  // Adjust primary index locally
  if (primaryScheduleIndex.value != null) {
    if (primaryScheduleIndex.value == index) {
      primaryScheduleIndex.value = null;
    } else if (primaryScheduleIndex.value! > index) {
      primaryScheduleIndex.value = primaryScheduleIndex.value! - 1;
    }
  }
  if (userId == null) return;
  try {
    // Delete the schedule doc
    final toDelete = await FirebaseFirestore.instance
        .collection('schedules')
        .where('userId', isEqualTo: userId)
        .where('index', isEqualTo: index)
        .limit(1)
        .get();
    if (toDelete.docs.isNotEmpty) {
      await toDelete.docs.first.reference.delete();
    }
    // Reindex remaining schedules in Firestore
    final all = await FirebaseFirestore.instance
        .collection('schedules')
        .where('userId', isEqualTo: userId)
        .get();
    for (var doc in all.docs) {
      final idx = doc.data()['index'] as int? ?? 0;
      if (idx > index) {
        await doc.reference.update({'index': idx - 1});
      }
    }
  } catch (e) {
    debugPrint('Error deleting schedule: $e');
  }
}

enum Day { mon, tue, wed, thu, fri }

extension DayExtension on Day {
  String get label => ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'][index];

  // Helper method to store enum as string in Firestore
  String toFirestore() {
    return toString().split('.').last;
  }
}

class _Meeting {
  final Day day;
  final int start;
  final int end;
  const _Meeting(this.day, this.start, this.end);

  // Add Firestore conversion methods
  Map<String, dynamic> toFirestore() {
    return {
      'day': day.toFirestore(),
      'start': start,
      'end': end,
    };
  }

  factory _Meeting.fromFirestore(Map<String, dynamic> data) {
    return _Meeting(
      _DayHelper.fromString(data['day'] ?? 'mon'),
      data['start'] ?? 8,
      data['end'] ?? 9,
    );
  }
}

class _Course {
  final String title;
  final List<_Meeting> meetings;
  final String courseId; // Added courseId field to store the actual Firestore ID
  
  const _Course(this.title, this.meetings, {this.courseId = ''});
  
  String get code => title.split('–').first.trim();

  // Add Firestore conversion methods
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'meetings': meetings.map((m) => m.toFirestore()).toList(),
      'courseId': courseId,
    };
  }

  factory _Course.fromFirestore(Map<String, dynamic> data) {
    List<_Meeting> meetings = [];
    if (data['meetings'] is List) {
      meetings = List<Map<String,dynamic>>.from(data['meetings'])
          .map((m) => _Meeting.fromFirestore(m))
          .toList();
    } else if (data['meeting'] is Map) {
      meetings = [ _Meeting.fromFirestore(Map<String,dynamic>.from(data['meeting'])) ];
    }
    return _Course(
      data['title'] ?? 'Unknown Course',
      meetings,
      courseId: data['courseId'] ?? '',
    );
  }

  @override
  bool operator ==(Object o) {
    if (o is _Course) {
      // Compare by title (which includes code) for more reliable equality
      return title == o.title || code == o.code;
    }
    return false;
  }
  @override
  int get hashCode => title.hashCode;
}

class SchedulePage extends StatefulWidget {
  final int index;
  const SchedulePage({super.key, required this.index});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  // Keep original catalog as fallback
  final _staticCatalog = <_Course>[
    _Course('CS301–Algorithms', [const _Meeting(Day.mon, 9, 12)], courseId: 'static-1'),
    _Course('CS302–Formal Languages', [const _Meeting(Day.tue, 12, 15)], courseId: 'static-2'),
    _Course('CS305–Programming Languages', [const _Meeting(Day.thu, 8, 11)], courseId: 'static-3'),
  ];

  List<_Course> _catalog = [];
  final Set<_Course> _selected = {};
  String _query = '';
  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Only proceed if user is logged in
      if (_userId == null) {
        setState(() {
          _catalog = _staticCatalog;
          _isLoading = false;
        });
        return;
      }

      // Load course catalog from Firestore
      final catalogSnapshot = await FirebaseFirestore.instance
          .collection('courses')
          .get();

      List<_Course> loadedCatalog = [];

      if (catalogSnapshot.docs.isNotEmpty) {
        // Convert Firestore documents to Course objects
        for (var doc in catalogSnapshot.docs) {
          final data = doc.data();
          // Get the first session for display in the schedule
          final List<dynamic> sessions = data['sessions'] ?? [];
          if (sessions.isNotEmpty) {
            final sessionData = sessions[0];
            final String day = sessionData['day'] ?? 'mon';
            final int startHour = sessionData['startHour'] ?? 9;
            final int endHour = sessionData['endHour'] ?? 10;
            
            loadedCatalog.add(_Course(
              '${data['code'] ?? 'Unknown'}–${data['name'] ?? 'Course'}',
              [_Meeting(
                _DayHelper.fromString(day),
                startHour,
                endHour,
              )],
              courseId: doc.id, // Store the Firestore document ID
            ));
          } else {
            // If no sessions, use default meeting time
            loadedCatalog.add(_Course(
              '${data['code'] ?? 'Unknown'}–${data['name'] ?? 'Course'}',
              [_Meeting(
                _DayHelper.fromString(data['day'] ?? 'mon'),
                data['startHour'] ?? 9,
                data['endHour'] ?? 10,
              )],
              courseId: doc.id, // Store the Firestore document ID
            ));
          }
        }
      }

      // If no courses were found in Firestore, use static catalog
      if (loadedCatalog.isEmpty) {
        loadedCatalog = _staticCatalog;
      }

      // Load saved schedules for this user
      if (widget.index >= 0 && widget.index < savedSchedules.value.length) {
        // First check local storage (ValueNotifier)
        _selected.addAll(savedSchedules.value[widget.index]);
      } else if (widget.index >= 0) {
        // If not in local storage, try to load from Firestore
        try {
          final scheduleSnapshot = await FirebaseFirestore.instance
              .collection('schedules')
              .where('userId', isEqualTo: _userId)
              .where('index', isEqualTo: widget.index)
              .limit(1)
              .get();

          if (scheduleSnapshot.docs.isNotEmpty) {
            final data = scheduleSnapshot.docs.first.data();
            if (data['courses'] != null && data['courses'] is List) {
              for (var courseData in data['courses']) {
                _selected.add(_Course.fromFirestore(courseData));
              }
            }
          }
        } catch (e) {
          // If Firestore fails, just use local data
          debugPrint('Error loading schedule from Firestore: $e');
        }
      }

      setState(() {
        _catalog = loadedCatalog;
        _isLoading = false;
      });
    } catch (e) {
      // On any error, fallback to static data
      setState(() {
        _catalog = _staticCatalog;
        _isLoading = false;
      });
    }
  }

  void _saveSchedule() async {
    // Capture the context before the async gap
    final currentContext = context;

    // First update local state (ValueNotifier)
    final list = List<Set<_Course>>.from(savedSchedules.value);
    if (widget.index == -1) {
      list.add(Set<_Course>.from(_selected));
    } else {
      if (widget.index >= list.length) {
        list.add(Set<_Course>.from(_selected));
      } else {
        list[widget.index] = Set<_Course>.from(_selected);
      }
    }
    savedSchedules.value = list;

    // Then save to Firestore if user is logged in
    if (_userId != null) {
      try {
        // Convert selected courses to Firestore format
        final List<Map<String, dynamic>> coursesData =
        _selected.map((course) => course.toFirestore()).toList();

        // Determine the index to save at
        final int saveIndex = widget.index == -1 ? list.length - 1 : widget.index;

        // Include primary flag
        final isPrimary = (primaryScheduleIndex.value == saveIndex);

        // Check if schedule already exists for this user and index
        final querySnapshot = await FirebaseFirestore.instance
            .collection('schedules')
            .where('userId', isEqualTo: _userId)
            .where('index', isEqualTo: saveIndex)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          // Update existing schedule
          await FirebaseFirestore.instance
              .collection('schedules')
              .doc(querySnapshot.docs.first.id)
              .update({
            'courses': coursesData,
            'updatedAt': FieldValue.serverTimestamp(),
            'primary': isPrimary,
          });
        } else {
          // Create new schedule
          await FirebaseFirestore.instance
              .collection('schedules')
              .add({
            'userId': _userId,
            'index': saveIndex,
            'courses': coursesData,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'primary': isPrimary,
          });
        }
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Schedule saved successfully')),
        );
      } catch (e) {
        // If Firestore save fails, at least the local save worked
        debugPrint('Error saving schedule to Firestore: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving schedule: ${e.toString()}')),
        );
      }
    }

    // Use the captured context for navigation
    if (mounted) {
      Navigator.pop(currentContext);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          widget.index == -1
              ? 'New Schedule'
              : 'Schedule ${widget.index + 1}',
          style: AppStyles.screenTitle.copyWith(color: AppColors.surface),
        ),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.surface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: AppColors.surface),
            onPressed: _saveSchedule,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(32),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search courses…',
                    border: InputBorder.none,
                  ),
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              color: AppColors.surface,
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Schedule Summary',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Total Courses: ${_selected.length}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          if (_selected.isNotEmpty)
                            Text(
                              'Days: ${_selected.map((c) => c.meetings.map((m) => m.day.label)).expand((i) => i).toSet().join(', ')}',
                              style: const TextStyle(fontSize: 14),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          'Time Range',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (_selected.isNotEmpty)
                          Text(
                            '${_selected.map((c) => c.meetings.map((m) => m.start)).expand((i) => i).reduce((a, b) => a < b ? a : b)}:00 - '
                            '${_selected.map((c) => c.meetings.map((m) => m.end)).expand((i) => i).reduce((a, b) => a > b ? a : b)}:00',
                            style: const TextStyle(fontSize: 14),
                          )
                        else
                          const Text('No courses selected', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            height: 210,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _catalog
                  .where((c) => _query.isEmpty ||
                  c.title.toLowerCase().contains(_query.toLowerCase()))
                  .map(_courseTile)
                  .toList(),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Material(
                elevation: 3,
                borderRadius: BorderRadius.circular(12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    color: AppColors.surface,
                    padding: const EdgeInsets.all(8),
                    child: _TimeTable(selected: _selected.toList()),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _courseTile(_Course c) {
    final picked = _selected.contains(c);
    
    // Determine if there's any schedule overlap
    bool hasOverlap = false;
    String overlappingCourse = "";
    
    for (final selectedCourse in _selected) {
      for (final selectedMeeting in selectedCourse.meetings) {
        for (final meeting in c.meetings) {
          if (selectedMeeting.day == meeting.day) {
            bool hoursOverlap = (meeting.start < selectedMeeting.end && 
                                meeting.end > selectedMeeting.start);
            
            if (hoursOverlap) {
              hasOverlap = true;
              overlappingCourse = selectedCourse.code;
              break;
            }
          }
        }
        if (hasOverlap) break;
      }
      if (hasOverlap) break;
    }
    
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        dense: true,
        title: Text(c.title, overflow: TextOverflow.ellipsis),
        subtitle: FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('courses')
              .where('code', isEqualTo: c.code)
              .limit(1)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Loading prerequisites...');
            }
            
            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Text('No prerequisites info');
            }
            
            final courseData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
            final List<dynamic> requirements = courseData['requirements'] ?? [];
            
            // Time conflict warning
            if (hasOverlap) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (requirements.isNotEmpty)
                    Text('Prerequisites: ${requirements.join(', ')}'),
                  Text(
                    'Time conflict with $overlappingCourse',
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ],
              );
            }
            
            if (requirements.isEmpty) {
              return const Text('No prerequisites required');
            }
            
            return Text('Prerequisites: ${requirements.join(', ')}');
          },
        ),
        trailing: IconButton(
          icon: Icon(
            picked ? Icons.bookmark : Icons.bookmark_border,
            color: picked ? Colors.amber : (hasOverlap ? Colors.red : Colors.grey),
          ),
          onPressed: () {
            if (picked) {
              // Find courses with the same code to remove
              final courseCode = c.code;
              final coursesToRemove = _selected.where((course) => course.code == courseCode).toList();
              setState(() {
                for (final course in coursesToRemove) {
                  _selected.remove(course);
                }
              });
            } else {
              _checkPrerequisitesAndAdd(c);
            }
          },
        ),
      ),
    );
  }

  void _checkPrerequisitesAndAdd(_Course course) async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to add courses')),
      );
      return;
    }

    try {
      // STEP 1: First check for time overlap with already selected courses
      bool hasOverlap = false;
      String overlappingCourse = "";
      
      for (final selectedCourse in _selected) {
        for (final selectedMeeting in selectedCourse.meetings) {
          for (final meeting in course.meetings) {
            if (selectedMeeting.day == meeting.day) {
              bool hoursOverlap = (meeting.start < selectedMeeting.end && 
                                  meeting.end > selectedMeeting.start);
              
              if (hoursOverlap) {
                hasOverlap = true;
                overlappingCourse = selectedCourse.code;
                break;
              }
            }
          }
          if (hasOverlap) break;
        }
        if (hasOverlap) break;
      }
      
      if (hasOverlap) {
        debugPrint('Schedule conflict: ${course.code} conflicts with $overlappingCourse');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot add ${course.code}: Schedule conflict with $overlappingCourse'),
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      // STEP 2: Check if courseId is empty or static, if so try to get it from the database
      String courseId = course.courseId;
      if (courseId.isEmpty || courseId.startsWith('static')) {
        final courseCode = course.code;
        debugPrint('Looking up courseId for $courseCode');
        final courseSnapshot = await FirebaseFirestore.instance
            .collection('courses')
            .where('code', isEqualTo: courseCode)
            .limit(1)
            .get();
            
        if (courseSnapshot.docs.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Course information not found for $courseCode')),
          );
          return;
        }
        
        courseId = courseSnapshot.docs.first.id;
        debugPrint('Found courseId: $courseId for $courseCode');
      }
      
      // STEP 3: Get the course prerequisites
      final courseDoc = await FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .get();
          
      if (!courseDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Course information not found')),
        );
        return;
      }
      
      final courseData = courseDoc.data();
      final List<dynamic> prerequisites = courseData?['requirements'] ?? [];
      
      if (prerequisites.isEmpty) {
        // No prerequisites, add the course to schedule
        debugPrint('No prerequisites for ${course.code}, adding to schedule');
        setState(() => _selected.add(course));
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added ${course.code} to your schedule')),
        );
        return;
      }
      
      debugPrint('Prerequisites for ${course.code}: ${prerequisites.join(", ")}');
      
      // STEP 4: Get all user's completed courses
      final userCoursesSnapshot = await FirebaseFirestore.instance
          .collection('user_course_data')
          .where('createdBy', isEqualTo: _userId)
          .where('isCompleted', isEqualTo: true)
          .get();
          
      // Get course IDs and codes of all completed courses
      final completedCourseIds = userCoursesSnapshot.docs.map((doc) => doc.data()['courseId'] as String).toList();
      final completedCourseCodes = <String>[];
      
      for (String id in completedCourseIds) {
        final courseDoc = await FirebaseFirestore.instance
            .collection('courses')
            .doc(id)
            .get();
            
        if (courseDoc.exists) {
          final code = courseDoc.data()?['code'] as String?;
          if (code != null) completedCourseCodes.add(code);
        }
      }
      
      debugPrint('User completed courses: ${completedCourseCodes.join(", ")}');
      
      // STEP 5: Check if all prerequisites are in completed courses
      bool allPrerequisitesMet = true;
      final missingPrerequisites = <String>[];
      
      for (var prereq in prerequisites) {
        final String prerequisiteCode = prereq.toString();
        if (!completedCourseCodes.contains(prerequisiteCode)) {
          allPrerequisitesMet = false;
          missingPrerequisites.add(prerequisiteCode);
        }
      }
      
      if (allPrerequisitesMet) {
        // STEP 6: All prerequisites met, add the course
        debugPrint('All prerequisites met for ${course.code}, adding to schedule');
        setState(() => _selected.add(course));
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added ${course.code} to your schedule')),
        );
      } else {
        // STEP 7: Show missing prerequisites
        final prerequisitesList = missingPrerequisites.join(', ');
        debugPrint('Missing prerequisites for ${course.code}: $prerequisitesList');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot add ${course.code}: Missing prerequisites: $prerequisitesList'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error checking prerequisites: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
}

// Keep the existing _TimeTable widget exactly as it was
class _TimeTable extends StatelessWidget {
  final List<_Course> selected;
  const _TimeTable({required this.selected});

  static const _hours = [8, 9, 10, 11, 12, 13, 14, 15, 16, 17];

  @override
  Widget build(BuildContext context) {
    final matrix = <Day, Map<int, _Course?>>{
      for (var d in Day.values) d: {for (var h in _hours) h: null}
    };
    for (final c in selected) {
      for (final m in c.meetings) {
        for (int h = m.start; h < m.end; h++) {
          matrix[m.day]![h] = c;
        }
      }
    }

    final headerCells = <Widget>[];
    headerCells.add(_headerCell('Time'));
    for (final d in Day.values) {
      headerCells.add(_headerCell(d.label));
    }
    final headerRow = TableRow(
      decoration:
      const BoxDecoration(color: AppColors.background),
      children: headerCells,
    );

    final bodyRows = <TableRow>[];
    for (final h in _hours) {
      final rowCells = <Widget>[];
      rowCells.add(_timeCell(h));
      for (final d in Day.values) {
        rowCells.add(_courseCell(matrix[d]![h]));
      }
      bodyRows.add(TableRow(children: rowCells));
    }

    final allRows = <TableRow>[];
    allRows.add(headerRow);
    for (final r in bodyRows) {
      allRows.add(r);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultVerticalAlignment:
        TableCellVerticalAlignment.middle,
        columnWidths: const {
          0: FixedColumnWidth(60),
          1: FixedColumnWidth(90),
          2: FixedColumnWidth(90),
          3: FixedColumnWidth(90),
          4: FixedColumnWidth(90),
          5: FixedColumnWidth(90),
        },
        border:
        TableBorder.all(color: AppColors.text, width: .8),
        children: allRows,
      ),
    );
  }

  Widget _headerCell(String t) => Container(
    height: 32,
    alignment: Alignment.center,
    child: Text(t,
        style: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 12)),
  );

  Widget _timeCell(int h) => Container(
    height: 48,
    alignment: Alignment.center,
    child: Text('${h.toString().padLeft(2, '0')}:00',
        style: const TextStyle(fontSize: 12)),
  );

  Widget _courseCell(_Course? c) => Container(
    height: 48,
    alignment: Alignment.center,
    decoration: BoxDecoration(
        color: c == null ? AppColors.surface : Colors.lightBlueAccent.withOpacity(0.7),
        border: c != null ? Border.all(color: Colors.blue, width: 1.0) : null,
        boxShadow: c != null ? [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 2.0,
            spreadRadius: 0.0,
            offset: const Offset(0, 1),
          )
        ] : null,
    ),
    child: c == null 
      ? const Text('', style: TextStyle(fontSize: 12))
      : Padding(
          padding: const EdgeInsets.all(2.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                c.code,
                style: const TextStyle(
                  fontSize: 12, 
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                c.meetings.isNotEmpty ? '${c.meetings.first.start}:00-${c.meetings.first.end}:00' : '',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
  );
}