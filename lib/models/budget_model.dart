class BudgetModel {
  final String id; // "{userId}_{yyyy}_{mm}"
  final String userId;
  final int year;
  final int month;
  final double overall; // 0 = not set
  final Map<String, double> categories; // category → limit (0 = not set)

  BudgetModel({
    required this.id,
    required this.userId,
    required this.year,
    required this.month,
    this.overall = 0,
    this.categories = const {},
  });

  static String docId(String userId, int year, int month) =>
      '${userId}_${year}_${month.toString().padLeft(2, '0')}';

  factory BudgetModel.fromMap(Map<String, dynamic> map, String id) {
    return BudgetModel(
      id: id,
      userId: map['userId'] ?? '',
      year: map['year'] ?? DateTime.now().year,
      month: map['month'] ?? DateTime.now().month,
      overall: (map['overall'] ?? 0).toDouble(),
      categories: Map<String, double>.from(
        (map['categories'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, (v as num).toDouble())),
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'year': year,
        'month': month,
        'overall': overall,
        'categories': categories,
      };

  BudgetModel copyWith({
    double? overall,
    Map<String, double>? categories,
  }) =>
      BudgetModel(
        id: id,
        userId: userId,
        year: year,
        month: month,
        overall: overall ?? this.overall,
        categories: categories ?? this.categories,
      );
}
