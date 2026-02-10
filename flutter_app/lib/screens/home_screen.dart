import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/prediction_provider.dart';
import '../providers/history_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final area = TextEditingController();
  final bedrooms = TextEditingController();
  final bathrooms = TextEditingController();
  final stories = TextEditingController();
  final parking = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  // Dropdown values
  String mainroad = "yes";
  String prefarea = "yes";
  String furnishingstatus = "furnished";

  @override
  void dispose() {
    area.dispose();
    bedrooms.dispose();
    bathrooms.dispose();
    stories.dispose();
    parking.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PredictionProvider>(context);
    final historyProvider = Provider.of<HistoryProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Flat Price Prediction"),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              buildNumberField(
                controller: area,
                label: "Area (sq.ft)",
                hint: "e.g., 1500",
                min: 500,
                max: 20000,
              ),
              buildNumberField(
                controller: bedrooms,
                label: "Bedrooms (rooms)",
                hint: "e.g., 3",
                min: 1,
                max: 10,
                isInteger: true,
              ),
              buildNumberField(
                controller: bathrooms,
                label: "Bathrooms (rooms)",
                hint: "e.g., 2",
                min: 1,
                max: 10,
                isInteger: true,
              ),
              buildNumberField(
                controller: stories,
                label: "Stories (floors)",
                hint: "e.g., 2",
                min: 1,
                max: 10,
                isInteger: true,
              ),
              buildNumberField(
                controller: parking,
                label: "Parking (spaces)",
                hint: "e.g., 1",
                min: 0,
                max: 10,
                isInteger: true,
              ),

              // Dropdown for Main Road
              buildDropdownField(
                label: "Main Road Access",
                value: mainroad,
                items: const ["yes", "no"],
                onChanged: (val) => setState(() => mainroad = val!),
              ),

              // Dropdown for Preferred Area
              buildDropdownField(
                label: "Preferred Area",
                value: prefarea,
                items: const ["yes", "no"],
                onChanged: (val) => setState(() => prefarea = val!),
              ),

              // Dropdown for Furnishing Status
              buildDropdownField(
                label: "Furnishing Status",
                value: furnishingstatus,
                items: const ["furnished", "semi-furnished", "unfurnished"],
                onChanged: (val) => setState(() => furnishingstatus = val!),
              ),

              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667eea).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: provider.loading
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;

                          final data = {
                            "area": int.parse(area.text),
                            "bedrooms": int.parse(bedrooms.text),
                            "bathrooms": int.parse(bathrooms.text),
                            "stories": int.parse(stories.text),
                            "parking": int.parse(parking.text),

                            // User-selected dropdown values
                            "mainroad": mainroad,
                            "prefarea": prefarea,
                            "furnishingstatus": furnishingstatus,

                            // Fixed backend requirements
                            "guestroom": "no",
                            "basement": "no",
                            "hotwaterheating": "no",
                            "airconditioning": "yes",
                          };

                          await provider.predict(data);
                          
                          // Save to history if prediction was successful
                          if (provider.errorMessage.isEmpty && provider.price > 0) {
                            await historyProvider.addPrediction(data, provider.price);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Prediction saved to history"),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: provider.loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.calculate, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              "Predict Price",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // ===== RESULT SECTION =====
              if (provider.loading) const CircularProgressIndicator(),

              if (provider.errorMessage.isNotEmpty)
                AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(milliseconds: 500),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            provider.errorMessage,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (!provider.loading && provider.errorMessage.isEmpty && provider.price > 0)
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 800),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Opacity(
                        opacity: value,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF667eea).withOpacity(0.1),
                                Color(0xFF764ba2).withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Card(
                            elevation: 0,
                            color: Colors.transparent,
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline,
                                    color: Color(0xFF667eea),
                                    size: 48,
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    "Predicted Price",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ShaderMask(
                                    shaderCallback: (bounds) => const LinearGradient(
                                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                                    ).createShader(bounds),
                                    child: Text(
                                      "Rs. ${provider.price.toStringAsFixed(2)}",
                                      style: const TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                )
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForField(String label) {
    if (label.contains('Area')) return Icons.square_foot;
    if (label.contains('Bedrooms')) return Icons.bed;
    if (label.contains('Bathrooms')) return Icons.bathroom;
    if (label.contains('Stories')) return Icons.layers;
    if (label.contains('Parking')) return Icons.local_parking;
    return Icons.input;
  }

  Widget buildNumberField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required double min,
    required double max,
    bool isInteger = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        validator: (v) {
          if (v == null || v.isEmpty) return "Required";
          final num? value = double.tryParse(v);
          if (value == null) return "Numbers only";
          if (value < min || value > max) {
            return "Must be between $min and $max";
          }
          if (isInteger && value != value.toInt()) {
            return "Must be a whole number";
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(_getIconForField(label), color: Color(0xFF667eea)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
    );
  }

  IconData _getIconForDropdown(String label) {
    if (label.contains('Main Road')) return Icons.location_city;
    if (label.contains('Preferred')) return Icons.location_on;
    if (label.contains('Furnishing')) return Icons.chair;
    return Icons.arrow_drop_down;
  }

  Widget buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(_getIconForDropdown(label), color: Color(0xFF667eea)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item.replaceAll('-', ' ').toUpperCase()),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
