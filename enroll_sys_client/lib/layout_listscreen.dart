import 'package:flutter/material.dart';
//import './es_client_session.dart';
//import './layout_hier_top.dart';


Widget listscreenLayout = Scaffold(
  appBar: AppBar(
    title: const Text('강좌/신청된 목록'),
  ),
  body: SizedBox.expand(child: Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(child: Image.asset('images/dashatars.png', fit: BoxFit.contain)),
    ],
  ))
);

//EOF
