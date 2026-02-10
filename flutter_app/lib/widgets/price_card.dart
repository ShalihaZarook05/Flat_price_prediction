import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PriceCard extends StatelessWidget {
  final double price;

  const PriceCard({required this.price});

  @override
  Widget build(BuildContext context) {
    final formatted =
        NumberFormat.currency(symbol: "Rs. ", decimalDigits: 2)
            .format(price);

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Predicted Price",
                style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text(formatted,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
