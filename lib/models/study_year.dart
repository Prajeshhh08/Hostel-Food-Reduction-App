class StudyYear {
  final int id;
  final int yearNumber;
  final String label;

  const StudyYear({
    required this.id,
    required this.yearNumber,
    required this.label,
  });

  factory StudyYear.fromJson(Map<String, dynamic> json) {
    return StudyYear(
      id: (json['id'] as num).toInt(),
      yearNumber: (json['year_number'] as num).toInt(),
      label: json['label'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'year_number': yearNumber,
      'label': label,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudyYear && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
