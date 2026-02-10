import 'package:flutter/material.dart';
import '../services/admin_service.dart';

class AdminPredictionsScreen extends StatefulWidget {
  const AdminPredictionsScreen({super.key});

  @override
  State<AdminPredictionsScreen> createState() => _AdminPredictionsScreenState();
}

class _AdminPredictionsScreenState extends State<AdminPredictionsScreen> {
  List<dynamic> predictions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPredictions();
  }

  Future<void> _loadPredictions() async {
    setState(() => isLoading = true);
    try {
      final data = await AdminService.getAllPredictions();
      setState(() {
        predictions = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading predictions: $e')),
        );
      }
    }
  }

  Future<void> _deletePrediction(int predictionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Prediction'),
        content: const Text('Are you sure you want to delete this prediction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AdminService.deletePrediction(predictionId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prediction deleted successfully')),
        );
        _loadPredictions();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting prediction: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.analytics, size: 24),
            SizedBox(width: 8),
            Text("Prediction Management"),
          ],
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade600, Colors.green.shade800],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPredictions,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : predictions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.analytics_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No predictions found',
                        style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: predictions.length,
                  itemBuilder: (context, index) {
                    final prediction = predictions[index];
                    final input = prediction['input'] as Map<String, dynamic>;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Text(
                            '\$',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          'Price: \$${prediction['price']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          'User: ${prediction['user_email']} • ${_formatDate(prediction['created_at'])}',
                        ),
                        trailing: prediction['favorite'] == true
                            ? const Icon(Icons.favorite, color: Colors.red, size: 20)
                            : null,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Property Details:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _buildPropertyChip(
                                      Icons.square_foot,
                                      'Area: ${input['area']} sqft',
                                      Colors.blue,
                                    ),
                                    _buildPropertyChip(
                                      Icons.bed,
                                      'Beds: ${input['bedrooms']}',
                                      Colors.orange,
                                    ),
                                    _buildPropertyChip(
                                      Icons.bathroom,
                                      'Baths: ${input['bathrooms']}',
                                      Colors.purple,
                                    ),
                                    _buildPropertyChip(
                                      Icons.layers,
                                      'Stories: ${input['stories']}',
                                      Colors.green,
                                    ),
                                    _buildPropertyChip(
                                      Icons.local_parking,
                                      'Parking: ${input['parking']}',
                                      Colors.teal,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (input['mainroad'] == 'yes')
                                      _buildFeatureChip('Main Road', Icons.check_circle, Colors.green),
                                    if (input['guestroom'] == 'yes')
                                      _buildFeatureChip('Guest Room', Icons.meeting_room, Colors.blue),
                                    if (input['basement'] == 'yes')
                                      _buildFeatureChip('Basement', Icons.home_work, Colors.brown),
                                    if (input['hotwaterheating'] == 'yes')
                                      _buildFeatureChip('Hot Water', Icons.water_drop, Colors.red),
                                    if (input['airconditioning'] == 'yes')
                                      _buildFeatureChip('AC', Icons.ac_unit, Colors.lightBlue),
                                    if (input['prefarea'] == 'yes')
                                      _buildFeatureChip('Pref Area', Icons.location_on, Colors.purple),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Furnishing: ${input['furnishingstatus']}',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Divider(height: 24),
                                Center(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _deletePrediction(prediction['id']),
                                    icon: const Icon(Icons.delete),
                                    label: const Text('Delete Prediction'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildPropertyChip(IconData icon, String label, Color color) {
    return Chip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(label),
      backgroundColor: color.withOpacity(0.1),
    );
  }

  Widget _buildFeatureChip(String label, IconData icon, Color color) {
    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.white),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: color,
      labelStyle: const TextStyle(color: Colors.white),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }
}
