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
  final _Meeting meeting;
  const _Course(this.title, this.meeting);
  String get code => title.split('–').first.trim();

  // Add Firestore conversion methods
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'meeting': meeting.toFirestore(),
    };
  }

  factory _Course.fromFirestore(Map<String, dynamic> data) {
    return _Course(
      data['title'] ?? 'Unknown Course',
      _Meeting.fromFirestore(data['meeting'] ?? {}),
    );
  }

  @override
  bool operator ==(Object o) =>
      o is _Course && title == o.title && meeting == o.meeting;
  @override
  int get hashCode => title.hashCode ^ meeting.hashCode;
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
    _Course('CS301–Algorithms', const _Meeting(Day.mon, 9, 12)),
    _Course('CS302–Formal Languages', const _Meeting(Day.tue, 12, 15)),
    _Course('CS305–Programming Languages', const _Meeting(Day.thu, 8, 11)),
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
          loadedCatalog.add(_Course(
            '${data['code'] ?? 'Unknown'}–${data['name'] ?? 'Course'}',
            _Meeting(
              _DayHelper.fromString(data['day'] ?? 'mon'),
              data['startHour'] ?? 9,
              data['endHour'] ?? 12,
            ),
          ));
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
          });
        }
      } catch (e) {
        // If Firestore save fails, at least the local save worked
        debugPrint('Error saving schedule to Firestore: $e');
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
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        dense: true,
        title: Text(c.title, overflow: TextOverflow.ellipsis),
        trailing: IconButton(
          icon: Icon(
            picked ? Icons.bookmark : Icons.bookmark_border,
            color: picked ? Colors.amber : Colors.grey,
          ),
          onPressed: () => setState(() =>
          picked ? _selected.remove(c) : _selected.add(c)),
        ),
      ),
    );
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
      for (int h = c.meeting.start; h < c.meeting.end; h++) {
        matrix[c.meeting.day]![h] = c;
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
          1: FixedColumnWidth(80),
          2: FixedColumnWidth(80),
          3: FixedColumnWidth(80),
          4: FixedColumnWidth(80),
          5: FixedColumnWidth(80),
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
        color: c == null ? AppColors.surface : Colors.lightBlueAccent),
    child: Text(c?.code ?? '',
        style: const TextStyle(fontSize: 12)),
  );
}