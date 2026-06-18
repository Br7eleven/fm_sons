class TermsCondition {
  final int? id;
  final String title;
  final String description;
  final String applicableFor;
  final DateTime createdAt;

  const TermsCondition({
    this.id,
    required this.title,
    required this.description,
    required this.applicableFor,
    required this.createdAt,
  });

  TermsCondition copyWith({
    int? id,
    String? title,
    String? description,
    String? applicableFor,
    DateTime? createdAt,
  }) {
    return TermsCondition(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      applicableFor: applicableFor ?? this.applicableFor,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'applicable_for': applicableFor,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  factory TermsCondition.fromMap(Map<String, dynamic> map) {
    return TermsCondition(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String,
      applicableFor: map['applicable_for'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
