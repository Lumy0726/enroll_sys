import 'package:flutter/material.dart';
import './enroll_sys_client.dart';
import './layout_hier_top.dart';

void main() {
  //Start flutter UI
  EsClient.printMethodMode = PrintMethodMode.CUSTOM;
  EsClient.printMethodFunc = (Object? obj) => debugPrint(obj?.toString());
  runApp(hierTopWidget);
  //test code
  Future.delayed(
    const Duration(seconds : 3),
    () => EsClient.printMethod('test')
  );
}

//EOF
