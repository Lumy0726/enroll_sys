import 'package:enroll_sys_client/layout_hier_top.dart';
import 'package:flutter/material.dart';
import 'package:enroll_sys/enroll_sys.dart';
import './es_client_session.dart';
import './enroll_sys_client.dart';
//import './layout_hier_top.dart';


GlobalKey listscreenLayoutSfulKey = GlobalKey<ListscreenLayoutState>();
Widget listscreenLayout = Scaffold(
  appBar: AppBar(
    title: const Text('강좌/신청된 목록'),
    actions: const <Widget>[
      IconButtonAndWait(
        onWaiting: onRefreshButton,
        tooltip: '새로고침',
        childIcon: Icon(Icons.refresh),
      ),
      IconButtonAndWait(
        onWaiting: onSettingsButton,
        tooltip: '설정',
        childIcon: Icon(Icons.settings),
      ),
    ],
  ),
  body: SizedBox.expand(child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(child: Builder(builder: (context) {
        doUpdateCourseInfo();
        return ListscreenLayoutSful(
          key: listscreenLayoutSfulKey,
        );
      })),
      const SizedBox(
        height: 50,
        child: SliderSful(
          initValue: 10,
          min: 0,
          max: 100,
          divisions: 100,
          onChanged: onButtomSliderChanged,
        )
      )
    ],
  ))
);

void onButtomSliderChanged(BuildContext context, double value) {
  if (listscreenLayoutSfulKey.currentContext != null) {
    ListscreenLayoutState state =
      listscreenLayoutSfulKey.currentState as ListscreenLayoutState;
    state.onChanged(value);
  }
}

class ListscreenLayoutSful extends StatefulWidget {
  const ListscreenLayoutSful({
    super.key,
  });
  @override
  State<ListscreenLayoutSful> createState() => ListscreenLayoutState();
}
class ListscreenLayoutState extends State<ListscreenLayoutSful> {
  double position = 10;
  @override
  void initState() {
    super.initState();
  }
  void onChanged(double positionValue) {
    if (mounted) { setState(() => position = positionValue); }
  }
  @override
  Widget build(BuildContext context) {
    int pos = position.round();
    if (pos < 0) { pos = 0; }
    else if (pos > 100) { pos = 100; }
    if (pos == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 1,
            child: listscreen1,
          ),
          Container(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            height: 6,
          ),
          SizedBox(
            height: 0,
            child: listscreen2,
          ),
        ],
      );
    }
    else if (pos == 100) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 0,
            child: listscreen1,
          ),
          Container(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            height: 6,
          ),
          Expanded(
            flex: 1,
            child: listscreen2,
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 100 - pos,
          child: listscreen1,
        ),
        Container(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          height: 6,
        ),
        Expanded(
          flex: pos,
          child: listscreen2,
        ),
      ],
    );
  }
}






class ListscreenSful extends StatefulWidget {
  final int id;
  const ListscreenSful({
    super.key,
    required this.id,
  });
  @override
  State<ListscreenSful> createState() => ListscreenState();
}
class ListscreenState extends State<ListscreenSful> {
  Map<String, CourseInfo> courseInfoMap = {};
  @override
  void initState() {
    super.initState();
  }
  void onUpdateCourseInfo(Map<String, CourseInfo> courseInfoMapValue) {
    if (mounted) { setState(() => courseInfoMap = courseInfoMapValue); }
  }
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: courseInfoMap.length,
      itemBuilder: (BuildContext context, int index) {
        String key = courseInfoMap.keys.elementAt(index);
        return CourseInfoWidget(
          courseInfo: courseInfoMap[key]!,
          id: widget.id,
          index: index
        );
      }
    );
  }
}

GlobalKey listscreen1Key = GlobalKey<ListscreenState>();
GlobalKey listscreen2Key = GlobalKey<ListscreenState>();
Widget listscreen1 = Builder(builder: (context) => Container(
  padding: const EdgeInsets.all(8),
  color: Theme.of(context).colorScheme.secondaryContainer,
  child: ListscreenSful(key: listscreen1Key, id: 1),
));
Widget listscreen2 = Builder(builder: (context) => Container(
  padding: const EdgeInsets.all(8),
  color: Theme.of(context).colorScheme.tertiaryContainer,
  child: ListscreenSful(key: listscreen2Key, id: 2),
));








class CourseInfoWidget extends StatelessWidget {
  final CourseInfo courseInfo;
  final int id;
  final int index;
  const CourseInfoWidget({
    super.key,
    required this.courseInfo,
    required this.id,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      color: Theme.of(context).colorScheme.outline,
      child: Container(
        padding: const EdgeInsets.all(4),
        color: Theme.of(context).colorScheme.surface,
        child: buildChild(context),
      ),
    );
  }
  Widget buildChild(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(courseInfo.id),
              Text(getInfoTimesStr(context)),
              Text([courseInfo.proName, courseInfo.locationStr].join(', ')),
              Text(getDetailStr(context)),
            ],
          ),
        ),
        SizedBox(
          width: 50, height: 50,
          child: IconButtonAndWait(
            onWaiting: onCourseListButton,
            tooltip: (id == 2 ? '삭제' : '신청'),
            childIcon: (
              id == 2 ?
              const Icon(Icons.cancel) :
              const Icon(Icons.add)
            ),
          ),
        )
      ],
    );
  }
  String getInfoTimesStr(BuildContext context) {
    List<String> timesStrList = [];
    for (CourseTimeInfo infoTime in courseInfo.infoTimes) {
      timesStrList.add(infoTime.toString());
      //timesStrList.add(infoTime.value.toString());
    }
    return timesStrList.join(', ');
  }
  String getDetailStr(BuildContext context) {
    List<String> strList = [
      courseInfo.id,
      courseInfo.groupStr,
      '${courseInfo.cpoint}학점',
      '특이사항: ${courseInfo.etc}',
    ];
    return strList.join(', ');
  }
}





Future<void> onRefreshButton(BuildContext context) async {
  return doUpdateCourseInfo();
}

Future<void> onSettingsButton(BuildContext context) async {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Settings button clicked')));
}

Future<void> onCourseListButton(BuildContext context) async {
  CourseInfoWidget? courseInfoWidget =
    context.findAncestorWidgetOfExactType<CourseInfoWidget>();
  if (courseInfoWidget == null) {
    //Should not be null. Assert(not null).
    debugPrint('Error: assert(courseInfoWidget == null) is false');
    return;
  }
  if (courseInfoWidget.id == 1 || courseInfoWidget.id == 2) {
    //CASE OF: user clicked course add/remove button.
    Future<dynamic> resultF =
      EsClientSess.enrollCourse(
        courseInfoWidget.courseInfo.id,
        ((courseInfoWidget.id == 2) ? true : false) // cancel mode.
      );
    return resultF.then<void>(
      (value) {
        try {
          if (listscreen2Key.currentContext == null) { return; }
          if (value is! Map<String, dynamic>) {
            ScaffoldMessenger.of(listscreen2Key.currentContext!).showSnackBar(
              SnackBar(content: Text('Error: $value')));
            return;
          }
          dynamic getResultObj = value['getResult'];
          dynamic enrollmentResultObj = value['enrollmentResult'];
          dynamic enrolledListObj = value['enrolledList'];
          if (
            enrollmentResultObj == null ||
            enrollmentResultObj is! String ||
            enrollmentResultObj != 'complete'
          ) {
            if (courseInfoWidget.id == 1) {
              ScaffoldMessenger.of(listscreen2Key.currentContext!).showSnackBar(
                SnackBar(content: Text('Enrollment failed: '
                  '$enrollmentResultObj')));
            }
            else {
              ScaffoldMessenger.of(listscreen2Key.currentContext!).showSnackBar(
                SnackBar(content: Text('Cancel enrollment failed: '
                  '$enrollmentResultObj')));
            }
          }
          else {
            if (courseInfoWidget.id == 1) {
              ScaffoldMessenger.of(listscreen2Key.currentContext!).showSnackBar(
                const SnackBar(content: Text('Enrollment complete')));
            }
            else {
              ScaffoldMessenger.of(listscreen2Key.currentContext!).showSnackBar(
                const SnackBar(content: Text('Cancel enrollment complete')));
            }
          }
          if (
            getResultObj == null ||
            getResultObj is! String ||
            getResultObj != 'complete' ||
            enrolledListObj == null ||
            enrolledListObj is! Map<String, dynamic>
          ) {
            ScaffoldMessenger.of(listscreen2Key.currentContext!).showSnackBar(
              const SnackBar(content: Text('Error: '
                'Getting current enrolled course failed')));
          }
          else {
            Map<String, CourseInfo> result = {};
            for (var entry in enrolledListObj.entries) {
              result[entry.key] = CourseInfo.fromJson(entry.value);
            }
            var state = listscreen2Key.currentState as ListscreenState;
            state.onUpdateCourseInfo(result);
          }
        }
        catch (e) {
          EsClient.printMethod(e.toString());
        }
      },
      onError: (e) {
        EsClient.printMethod(e.toString());
      }
    );
  }
  else {
    //Should not be here.
    debugPrint('Error: courseInfoWidget.id is not 1 or 2');
    return;
  }
}

bool isUpdating = false;
Future<void> doUpdateCourseInfo() async {
  if (isUpdating) return;
  isUpdating = true;
  int resultCount = 2;
  Future<dynamic> resultF = EsClientSess.getCourse('');
  resultF.then<void>(
    (value) {
      resultCount--;
      if (resultCount == 0) { isUpdating = false; }
      try {
        if (listscreen1Key.currentContext != null) {
          if (value is! Map<String, dynamic>) {
            ScaffoldMessenger.of(listscreen1Key.currentContext!).showSnackBar(
              SnackBar(content: Text('Error: $value')));
            return;
          }
        }
        if (resultCount == 0) {
          ScaffoldMessenger.of(listscreen2Key.currentContext!).showSnackBar(
            const SnackBar(content: Text('Course list refreshed')));
        }
        Map<String, CourseInfo> result = {};
        for (var entry in value.entries) {
          result[entry.key] = CourseInfo.fromJson(entry.value);
        }
        if (listscreen1Key.currentState != null) {
          var state = listscreen1Key.currentState as ListscreenState;
          state.onUpdateCourseInfo(result);
        }
      }
      catch (e) {
        EsClient.printMethod(e.toString());
      }
    },
    onError: (e) {
      resultCount--;
      if (resultCount == 0) { isUpdating = false; }
      EsClient.printMethod(e.toString());
    }
  );
  Future<dynamic> resultF2 = EsClientSess.getCourseEnrolled();
  resultF2.then<void>(
    (value) {
      resultCount--;
      if (resultCount == 0) { isUpdating = false; }
      try {
        if (listscreen2Key.currentContext != null) {
          if (value is! Map<String, dynamic>) {
            ScaffoldMessenger.of(listscreen2Key.currentContext!).showSnackBar(
              SnackBar(content: Text('Error: $value')));
            return;
          }
        }
        if (resultCount == 0) {
          ScaffoldMessenger.of(listscreen2Key.currentContext!).showSnackBar(
            const SnackBar(content: Text('Course list refreshed')));
        }
        Map<String, CourseInfo> result = {};
        for (var entry in value.entries) {
          result[entry.key] = CourseInfo.fromJson(entry.value);
        }
        if (listscreen2Key.currentState != null) {
          var state = listscreen2Key.currentState as ListscreenState;
          state.onUpdateCourseInfo(result);
        }
      }
      catch (e) {
        EsClient.printMethod(e.toString());
      }
    },
    onError: (e) {
      resultCount--;
      if (resultCount == 0) { isUpdating = false; }
      EsClient.printMethod(e.toString());
    }
  );
  Future<dynamic> resultAll = Future.wait([resultF, resultF2]);
  return resultAll.then<void>(
    (value) { return; },
    onError: (e) { return; }
  );
}


//EOF
