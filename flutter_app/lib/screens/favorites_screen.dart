import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/history_provider.dart';
import 'package:intl/intl.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<HistoryProvider>(context);
    final favorites = provider.favorites;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.favorite, size: 24),
            SizedBox(width: 8),
            Text("Favorites"),
          ],
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          if (favorites.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: "Info",
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('You have ${favorites.length} favorite prediction(s)'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
        ],
      ),

      body: favorites.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final item = favorites[index];
                return _buildFavoriteCard(context, item, provider);
              },
            ),
    );
  }

  // ================= EMPTY STATE =================

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),

          Text(
            "No Favorites Yet",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "Mark predictions as favorites to see them here",
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ================= CARD =================

  Widget _buildFavoriteCard(
      BuildContext context, dynamic item, HistoryProvider provider) {
    return Hero(
      tag: 'favorite_${item.id}',
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 3,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.red.withOpacity(0.2), width: 2),
        ),

        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showDetailsDialog(context, item),

          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),

              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.red.withOpacity(0.05),
                  Colors.pink.withOpacity(0.05),
                ],
              ),
            ),

            child: Padding(
              padding: const EdgeInsets.all(16),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Row(
                              children: [
                                const Icon(Icons.favorite,
                                    color: Colors.red, size: 20),

                                const SizedBox(width: 8),

                                Expanded(
                                  child: Text(
                                    "Rs. ${item.predictedPrice.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 4),

                            Text(
                              DateFormat('MMM dd, yyyy - hh:mm a')
                                  .format(item.timestamp),
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      IconButton(
                        icon: const Icon(Icons.favorite),
                        color: Colors.red,
                        onPressed: () => provider.toggleFavorite(item.id),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),

                  _buildPropertyInfo(item.input),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================= PROPERTY INFO =================

  Widget _buildPropertyInfo(Map<String, dynamic> input) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildInfoChip(Icons.straighten, "${input['area']} sq.ft", Colors.blue),
        _buildInfoChip(Icons.bed, "${input['bedrooms']} beds", Colors.green),
        _buildInfoChip(Icons.bathtub, "${input['bathrooms']} baths", Colors.orange),
        _buildInfoChip(Icons.layers, "${input['stories']} floors", Colors.purple),
        _buildInfoChip(Icons.local_parking, "${input['parking']} parking", Colors.teal),
      ],
    );
  }

  // ================= CHIP (FIXED) =================

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [

          Icon(icon, size: 16, color: color),

          const SizedBox(width: 4),

          // ✅ FIXED: no shade700
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ================= DETAILS DIALOG =================

  void _showDetailsDialog(BuildContext context, dynamic item) {
    showDialog(
      context: context,

      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.favorite, color: Colors.red),
            SizedBox(width: 8),
            Text("Favorite Property"),
          ],
        ),

        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              _buildDetailRow(
                  "Predicted Price",
                  "Rs. ${item.predictedPrice.toStringAsFixed(2)}"),

              _buildDetailRow("Area", "${item.input['area']} sq.ft"),
              _buildDetailRow("Bedrooms", "${item.input['bedrooms']}"),
              _buildDetailRow("Bathrooms", "${item.input['bathrooms']}"),
              _buildDetailRow("Stories", "${item.input['stories']}"),
              _buildDetailRow("Parking", "${item.input['parking']}"),

              _buildDetailRow("Main Road", "${item.input['mainroad']}"),
              _buildDetailRow("Preferred Area", "${item.input['prefarea']}"),
              _buildDetailRow("Furnishing", "${item.input['furnishingstatus']}"),

              _buildDetailRow(
                  "Date",
                  DateFormat('MMM dd, yyyy - hh:mm a')
                      .format(item.timestamp)),
            ],
          ),
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          Text(label,
              style: const TextStyle(fontWeight: FontWeight.bold)),

          Flexible(
              child: Text(value, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}
