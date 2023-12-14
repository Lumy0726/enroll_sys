import 'package:flutter/material.dart';
import './es_client_session.dart';
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

void onLoginInfoCheckbox(bool? value) {
  debugPrint(value.toString());
}
const Widget loginLayoutLeft = Column(
  children: [
    Expanded(child: Center(child: Text('ID'))),
    Expanded(child: Center(child: Text('PW'))),
    Expanded(child: Center(child: LoginInfoCheckbox(
      onChanged: onLoginInfoCheckbox,
    ))),
  ],
);
GlobalKey idWidgetKey = GlobalKey<TextFieldSfulState>();
GlobalKey pwWidgetKey = GlobalKey<TextFieldSfulState>();
Widget loginLayoutCenter = Expanded(child: Column(
  children: [
    Expanded(child: Container(
      alignment: Alignment.centerLeft,
      child: TextFieldSful(
        key: idWidgetKey,
        obscureText: false,
        labelText: 'ID'
      ),
    )),
    Expanded(child: Container(
      alignment: Alignment.centerLeft,
      child: TextFieldSful(
        key: pwWidgetKey,
        obscureText: true,
        labelText: 'PW'
      ),
    )),
    Expanded(child: Container(
      alignment: Alignment.centerLeft,
      child: const Text('로그인 정보 저장'),
    )),
  ],
));
Future<void> onLoginFunc() {
  String id = '';
  String pw = '';
  if (idWidgetKey.currentState != null) {
    TextFieldSfulState state = idWidgetKey.currentState as TextFieldSfulState;
    id = state.inputStr;
  }
  if (pwWidgetKey.currentState != null) {
    TextFieldSfulState state = pwWidgetKey.currentState as TextFieldSfulState;
    pw = state.inputStr;
  }
  return EsClientSess.doLogin(id, pw);
}
Widget loginLayoutRight = ConstrainedBox(
  constraints: const BoxConstraints.tightFor(width: 50),
  child: const Center(
    child: ButtonAndWait(
      onWaiting: onLoginFunc,
      child: Center(child: Icon(Icons.login)),
    ),
  )
);


class LoginInfoCheckbox extends StatefulWidget {
  final void Function(bool? value) onChanged;
  const LoginInfoCheckbox({
    super.key,
    required this.onChanged,
  });
  @override
  State<LoginInfoCheckbox> createState() => LoginInfoCheckboxState();
}
class LoginInfoCheckboxState extends State<LoginInfoCheckbox> {
  bool checked = true;
  void onChanged(bool? value) {
    widget.onChanged(value);
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
