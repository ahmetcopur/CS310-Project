import 'package:flutter/material.dart';
import 'package:su_credit/utils/colors.dart';
import 'package:su_credit/utils/styles.dart';

final ValueNotifier<List<Set<_Course>>> savedSchedules =
ValueNotifier<List<Set<_Course>>>([]);

enum Day { mon, tue, wed, thu, fri }
extension on Day {
  String get label => ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'][index];
}

class _Meeting {
  final Day day;
  final int start;
  final int end;
  const _Meeting(this.day, this.start, this.end);
}

class _Course {
  final String title;
  final _Meeting meeting;
  const _Course(this.title, this.meeting);
  String get code => title.split('–').first.trim();
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
  final _catalog = <_Course>[
    _Course('CS301–Algorithms', const _Meeting(Day.mon, 9, 12)),
    _Course('CS302–Formal Languages', const _Meeting(Day.tue, 12, 15)),
    _Course('CS305–Programming Languages', const _Meeting(Day.thu, 8, 11)),
  ];

  final Set<_Course> _selected = {};
  String _query = '';

  @override
  void initState() {
    super.initState();
    if (widget.index >= 0 && widget.index < savedSchedules.value.length) {
      _selected.addAll(savedSchedules.value[widget.index]);
    }
  }

  void _saveSchedule() {
    final list = List<Set<_Course>>.from(savedSchedules.value);
    if (widget.index == -1) {
      list.add(Set<_Course>.from(_selected));
    } else {
      list[widget.index] = Set<_Course>.from(_selected);
    }
    savedSchedules.value = list;
    Navigator.pop(context);
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(32),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search courses…',
                          border: InputBorder.none,
                        ),
                        onChanged: (v) => setState(() => _query = v.trim()),
                      ),
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
                  .where((c) =>
              _query.isEmpty ||
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
        // leading icon removed per request
        title: Text(c.title, overflow: TextOverflow.ellipsis),
        trailing: IconButton(
          icon: Icon(
            picked ? Icons.bookmark : Icons.bookmark_border,
            color: picked ? Colors.amber : Colors.grey,
          ),
          onPressed: () =>
              setState(() => picked ? _selected.remove(c) : _selected.add(c)),
        ),
      ),
    );
  }
}

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
    for (final d in Day.values) headerCells.add(_headerCell(d.label));

    final bodyRows = <TableRow>[];
    for (final h in _hours) {
      final rowCells = <Widget>[];
      rowCells.add(_timeCell(h));
      for (final d in Day.values) rowCells.add(_courseCell(matrix[d]![h]));
      bodyRows.add(TableRow(children: rowCells));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: const {
          0: FixedColumnWidth(60),
          1: FixedColumnWidth(80),
          2: FixedColumnWidth(80),
          3: FixedColumnWidth(80),
          4: FixedColumnWidth(80),
          5: FixedColumnWidth(80),
        },
        border: TableBorder.all(color: AppColors.text, width: .8),
        children: [
          TableRow(
            decoration: const BoxDecoration(color: AppColors.backgroundColor),
            children: headerCells,
          ),
          ...bodyRows,
        ],
      ),
    );
  }

  Widget _headerCell(String t) => Container(
    height: 32,
    alignment: Alignment.center,
    child: Text(t,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
    child: Text(c?.code ?? '', style: const TextStyle(fontSize: 12)),
  );
}