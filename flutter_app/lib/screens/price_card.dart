import 'package:flutter/material.dart';

class PriceCard extends StatelessWidget {

  final String price;

  PriceCard({required this.price});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text("Estimated Price",
                style: TextStyle(fontSize: 16)),

            SizedBox(height: 10),

            Text(price,
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.green))
          ],
        ),
      ),
    );
  }
}
