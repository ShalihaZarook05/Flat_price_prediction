import 'package:flutter/material.dart';

class HistorySection extends StatelessWidget {
  final List<String> history;

  const HistorySection({required this.history});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Previous Predictions",
            style: TextStyle(fontWeight: FontWeight.bold)),
        ...history.map((e) => ListTile(
              title: Text(e),
            ))
      ],
    );
  }
}
