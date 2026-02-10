class PredictionHistory {
  final String id;
  final Map<String, dynamic> input;
  final double predictedPrice;
  final DateTime timestamp;
  bool isFavorite;

  PredictionHistory({
    required this.id,
    required this.input,
    required this.predictedPrice,
    required this.timestamp,
    this.isFavorite = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'input': input,
        'predictedPrice': predictedPrice,
        'timestamp': timestamp.toIso8601String(),
        'isFavorite': isFavorite,
      };

  factory PredictionHistory.fromJson(Map<String, dynamic> json) {
    return PredictionHistory(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      input: Map<String, dynamic>.from(json['input'] ?? {}),
      predictedPrice: (json['predictedPrice'] ?? json['price'] ?? 0.0).toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  PredictionHistory copyWith({
    String? id,
    Map<String, dynamic>? input,
    double? predictedPrice,
    DateTime? timestamp,
    bool? isFavorite,
  }) {
    return PredictionHistory(
      id: id ?? this.id,
      input: input ?? this.input,
      predictedPrice: predictedPrice ?? this.predictedPrice,
      timestamp: timestamp ?? this.timestamp,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
