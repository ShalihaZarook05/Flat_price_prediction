import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/history_provider.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<HistoryProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.history, size: 24),
            SizedBox(width: 8),
            Text("Prediction History"),
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
          if (provider.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: "Clear All",
              onPressed: () => _showClearDialog(context, provider),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
            onPressed: () => provider.reload(),
          ),
        ],
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.items.isEmpty
              ? _buildEmptyState()
              : AnimatedList(
                  key: GlobalKey<AnimatedListState>(),
                  initialItemCount: provider.items.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index, animation) {
                    final item = provider.items[index];
                    return _buildHistoryCard(context, item, provider, animation);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "No Predictions Yet",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Your prediction history will appear here",
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(
    BuildContext context,
    item,
    HistoryProvider provider,
    Animation<double> animation,
  ) {
    return SlideTransition(
      position: animation.drive(
        Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOut)),
      ),
      child: FadeTransition(
        opacity: animation,
        child: Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showDetailsDialog(context, item),
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
                            Text(
                              "Rs. ${item.predictedPrice.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('MMM dd, yyyy - hh:mm a')
                                  .format(item.timestamp),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              item.isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: item.isFavorite ? Colors.red : null,
                            ),
                            onPressed: () => provider.toggleFavorite(item.id),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () =>
                                _showDeleteDialog(context, item.id, provider),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(),
                  _buildPropertyInfo(item.input),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyInfo(Map<String, dynamic> input) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildInfoChip(Icons.straighten, "${input['area']} sq.ft"),
        _buildInfoChip(Icons.bed, "${input['bedrooms']} beds"),
        _buildInfoChip(Icons.bathtub, "${input['bathrooms']} baths"),
        _buildInfoChip(Icons.layers, "${input['stories']} floors"),
        _buildInfoChip(Icons.local_parking, "${input['parking']} parking"),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  void _showDetailsDialog(BuildContext context, item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Property Details"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow("Predicted Price", 
                  "Rs. ${item.predictedPrice.toStringAsFixed(2)}"),
              _buildDetailRow("Area", "${item.input['area']} sq.ft"),
              _buildDetailRow("Bedrooms", "${item.input['bedrooms']}"),
              _buildDetailRow("Bathrooms", "${item.input['bathrooms']}"),
              _buildDetailRow("Stories", "${item.input['stories']}"),
              _buildDetailRow("Parking", "${item.input['parking']}"),
              _buildDetailRow("Main Road", "${item.input['mainroad']}"),
              _buildDetailRow("Preferred Area", "${item.input['prefarea']}"),
              _buildDetailRow("Furnishing", "${item.input['furnishingstatus']}"),
              _buildDetailRow("Date", 
                  DateFormat('MMM dd, yyyy - hh:mm a').format(item.timestamp)),
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
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String id, HistoryProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Prediction"),
        content: const Text("Are you sure you want to delete this prediction?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              provider.remove(id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Prediction deleted")),
              );
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showClearDialog(BuildContext context, HistoryProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear All History"),
        content: const Text("Are you sure you want to clear all predictions?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              provider.clearAll();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("All predictions cleared")),
              );
            },
            child: const Text("Clear All", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
