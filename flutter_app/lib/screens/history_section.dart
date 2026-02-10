import 'package:flutter/material.dart';

class HistorySection extends StatelessWidget {

  static List<String> history = [];

  @override
  Widget build(BuildContext context) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text("Previous Predictions",
            style: TextStyle(fontWeight: FontWeight.bold)),

        ...history.map((e) => ListTile(
              leading: Icon(Icons.history),
              title: Text(e),
            ))
      ],
    );
  }
}
