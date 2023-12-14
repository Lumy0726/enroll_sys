import 'package:flutter/material.dart';
import './enroll_sys_client.dart';
import './layout_hier_top.dart';

Widget loginLayout = Scaffold(
  body: SizedBox.expand(child: Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(child: Image.asset('images/dashatars.png', fit: BoxFit.contain)),
      Builder(builder: (context) => Container(
        height: 100,
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            loginLayoutLeft,
            loginLayoutCenter,
            loginLayoutRight,
          ],
        )
      )),
      Expanded(child: Image.asset('images/dashatars.png', fit: BoxFit.contain)),
    ],
  ))
);

const Widget loginLayoutLeft = Column(
  children: [
    Expanded(child: Center(child: Text('ID'))),
    Expanded(child: Center(child: Text('PW'))),
    Expanded(child: Center(child: LoginInfoCheckbox())),
  ],
);
Widget loginLayoutCenter = Expanded(child: Column(
  children: [
    Expanded(child: Container(
      alignment: Alignment.centerLeft,
      child: const TextFieldSful(obscureText: false, labelText: 'ID'),
    )),
    Expanded(child: Container(
      alignment: Alignment.centerLeft,
      child: const TextFieldSful(obscureText: true, labelText: 'PW'),
    )),
    Expanded(child: Container(
      alignment: Alignment.centerLeft,
      child: const Text('로그인 정보 저장'),
    )),
  ],
));
Future<void> onWaitingFunc() async {
  return Future.delayed(const Duration(seconds: 3), () => {});
}
Widget loginLayoutRight = ConstrainedBox(
  constraints: const BoxConstraints.tightFor(width: 50),
  child: const Center(
    child: ButtonAndWait(
      onWaiting: onWaitingFunc,
      child: Center(child: Icon(Icons.login)),
    ),
  )
);


class LoginInfoCheckbox extends StatefulWidget {
  const LoginInfoCheckbox({Key? key}) : super(key: key);
  @override
  State<LoginInfoCheckbox> createState() => LoginInfoCheckboxState();
}
class LoginInfoCheckboxState extends State<LoginInfoCheckbox> {
  bool checked = true;
  void onChanged(bool? value) {
    if (mounted) { setState(() => checked = value ?? true); }
  }
  @override
  Widget build(BuildContext context) {
    return Checkbox(
      value: checked,
      onChanged: onChanged,
    );
  }
}

//EOF
