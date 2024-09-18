import 'package:flutter/cupertino.dart';

List<Widget> joinWidgets(List<Widget> widgets, Widget separator) {
  List<Widget> result = [];
  for (Widget widget in widgets) {
    result.add(widget);
    if (widgets.last != widget) {
      result.add(separator);
    }
  }
  return result;
}
