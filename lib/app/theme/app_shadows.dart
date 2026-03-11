import 'package:flutter/material.dart';

class AppShadows {
  static const soft = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 15, offset: Offset(0, 4)),
  ];

  static const card = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 10, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x1A000000), blurRadius: 15, offset: Offset(0, 10)),
  ];

  static const elevatedCard = [
    BoxShadow(color: Color(0x40000000), blurRadius: 50, offset: Offset(0, 25)),
  ];
}
