class FoodItem {
  final int id;
  final String name;
  final int defaultPortionGrams;
  final bool active;
  final DateTime? createdAt;

  const FoodItem({
    required this.id,
    required this.name,
    this.defaultPortionGrams = 0,
    this.active = true,
    this.createdAt,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      defaultPortionGrams: (json['default_portion_grams'] as num?)?.toInt() ?? 0,
      active: json['active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'default_portion_grams': defaultPortionGrams,
      'active': active,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
