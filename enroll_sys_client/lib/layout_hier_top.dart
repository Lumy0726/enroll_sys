import 'package:flutter/material.dart';
//import './enroll_sys_client.dart';
import './layout_login.dart';

Widget hierTopWidget = MaterialApp(
  theme: ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
    //textTheme: const TextTheme(),
  ),
  home: loginLayout,
);



class WaitingCircle extends StatefulWidget {
  const WaitingCircle({super.key});
  @override
  State<WaitingCircle> createState() => _WaitingCircleState();
}
class _WaitingCircleState
  extends State<WaitingCircle>
  with TickerProviderStateMixin
{
  late AnimationController controller;
  @override
  void initState() {
    controller = AnimationController(
      /// [AnimationController]s can be created with `vsync: this` because of
      /// [TickerProviderStateMixin].
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addListener(() {
        setState(() {});
      });
    controller.repeat(reverse: false);
    super.initState();
  }
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return CircularProgressIndicator(
      value: controller.value,
      semanticsLabel: 'Waiting...',
    );
  }
}

class SliderSful extends StatefulWidget {
  final void Function(BuildContext, double) onChanged;
  final double min;
  final double max;
  final int divisions;
  final double initValue;
  const SliderSful({
    super.key,
    required this.onChanged,
    this.min = 0,
    this.max = 100,
    this.divisions = 100,
    this.initValue = 0,
  });
  @override
  State<SliderSful> createState() => SliderState();
}
class SliderState extends State<SliderSful> {
  double _currentSliderValue = 0;
  @override
  void initState() {
    _currentSliderValue = widget.initValue;
    super.initState();
  }
  void onChanged(double value) {
    widget.onChanged(context, value);
    if (mounted) { setState(() => _currentSliderValue = value); }
  }
  @override
  Widget build(BuildContext context) {
    return Slider(
      value: _currentSliderValue,
      min: widget.min,
      max: widget.max,
      divisions: widget.divisions,
      label: _currentSliderValue.round().toString(),
      onChanged: onChanged,
    );
  }
}

class IconButtonAndWait extends StatefulWidget {
  final Widget childIcon;
  final String tooltip;
  final Future Function(BuildContext) onWaiting;
  const IconButtonAndWait({
    super.key,
    required this.childIcon,
    this.tooltip = '',
    required this.onWaiting,
 });
  @override
  State<IconButtonAndWait> createState() => IconButtonAndWaitState();
}
class IconButtonAndWaitState extends State<IconButtonAndWait> {
  bool isWaiting = false;
  void onPressed() {
    isWaiting = true;
    Future<dynamic> resultF = widget.onWaiting(context);
    resultF.then<void>(
      (value) => {
        if (mounted) setState(() => isWaiting = false)
      },
      onError: (value) => {
        if (mounted) setState(() => isWaiting = false)
      },
    );
    if (mounted) { setState(() => isWaiting = true); }
  }
  @override
  Widget build(BuildContext context) {
    if (!isWaiting) {
      return IconButton(
        onPressed: onPressed,
        tooltip: widget.tooltip,
        icon: widget.childIcon,
      );
    }
    return const WaitingCircle();
  }
}

class ElevatedButtonAndWait extends StatefulWidget {
  final Widget child;
  final Future Function(BuildContext) onWaiting;
  const ElevatedButtonAndWait({
    super.key,
    required this.child,
    required this.onWaiting,
 });
  @override
  State<ElevatedButtonAndWait> createState() => ElevatedButtonAndWaitState();
}
class ElevatedButtonAndWaitState extends State<ElevatedButtonAndWait> {
  bool isWaiting = false;
  void onPressed() {
    isWaiting = true;
    Future<dynamic> resultF = widget.onWaiting(context);
    resultF.then<void>(
      (value) => {
        if (mounted) setState(() => isWaiting = false)
      },
      onError: (value) => {
        if (mounted) setState(() => isWaiting = false)
      },
    );
    if (mounted) { setState(() => isWaiting = true); }
  }
  @override
  Widget build(BuildContext context) {
    if (!isWaiting) {
      return ElevatedButton(
        onPressed: onPressed,
        child: widget.child,
      );
    }
    return const WaitingCircle();
  }
}

class TextFieldSful extends StatefulWidget {
  final bool obscureText;
  final String labelText;
  const TextFieldSful({
    super.key,
    this.obscureText = false,
    this.labelText = ''
  });
  @override
  State<TextFieldSful> createState() => TextFieldSfulState();
}
class TextFieldSfulState extends State<TextFieldSful> {
  late TextEditingController _controller;
  String inputStr = '';
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  void onChanged(String value) {
    inputStr = value;
    //EsClient.printMethod(inputStr);
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      child: TextField(
        controller: _controller,
        onChanged: onChanged,
        obscureText: widget.obscureText,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: widget.labelText,
        ),
      )
    );
  }
}


//EOF
