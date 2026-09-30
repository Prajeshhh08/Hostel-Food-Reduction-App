class Course {
  final int id;
  final String code;
  final String name;
  final bool active;
  final DateTime? createdAt;

  const Course({
    required this.id,
    required this.code,
    required this.name,
    this.active = true,
    this.createdAt,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: (json['id'] as num).toInt(),
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      active: json['active'] is bool
          ? json['active'] as bool
          : (json['active']?.toString().toLowerCase() != 'false'),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'active': active,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Course && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
