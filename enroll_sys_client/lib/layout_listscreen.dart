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
    actions: <Widget>[
      Builder(builder: (context) => IconButton(
        icon: const Icon(Icons.refresh),
        tooltip: '새로고침',
        onPressed: () => onRefreshButton(context),
      )),
      Builder(builder: (context) => IconButton(
        icon: const Icon(Icons.settings),
        tooltip: '설정',
        onPressed: () => onSettingsButton(context),
      )),
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
      height: 100,
      padding: const EdgeInsets.all(4),
      color: Theme.of(context).colorScheme.outline,
      child: Container(
        padding: const EdgeInsets.all(4),
        color: Theme.of(context).colorScheme.surface,
        child: Text(courseInfo.id),
      ),
    );
  }
}





void onRefreshButton(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('This is a snackbar')));
}

void onSettingsButton(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Settings button clicked')));
}

void doUpdateCourseInfo() {
  Future<dynamic> resultF = EsClientSess.getCourse('');
  resultF.then<void>(
    (value) {
      try {
        if (listscreen1Key.currentContext != null) {
          if (value is! Map<String, dynamic>) {
            ScaffoldMessenger.of(listscreen1Key.currentContext!).showSnackBar(
              SnackBar(content: Text(value.toString())));
          }
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
      EsClient.printMethod(e.toString());
    }
  );
  Future<dynamic> resultF2 = EsClientSess.getCourseEnrolled();
  resultF2.then<void>(
    (value) {
      try {
        if (listscreen2Key.currentContext != null) {
          if (value is! Map<String, dynamic>) {
            ScaffoldMessenger.of(listscreen2Key.currentContext!).showSnackBar(
              SnackBar(content: Text(value.toString())));
          }
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
      EsClient.printMethod(e.toString());
    }
  );
}


//EOF
