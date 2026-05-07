class ContractModel {
  final int? id;
  final String contractNumber;
  final String departmentName;
  final String? startDate;
  final String? endDate;
  final double? totalValue;
  final String status;
  final String? createdAt;
  final String? updatedAt;

  const ContractModel({
    this.id,
    required this.contractNumber,
    required this.departmentName,
    this.startDate,
    this.endDate,
    this.totalValue,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  ContractModel copyWith({
    int? id,
    String? contractNumber,
    String? departmentName,
    String? startDate,
    String? endDate,
    double? totalValue,
    String? status,
    String? createdAt,
    String? updatedAt,
  }) {
    return ContractModel(
      id: id ?? this.id,
      contractNumber: contractNumber ?? this.contractNumber,
      departmentName: departmentName ?? this.departmentName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalValue: totalValue ?? this.totalValue,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contract_number': contractNumber,
      'department_name': departmentName,
      'start_date': startDate,
      'end_date': endDate,
      'total_value': totalValue,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory ContractModel.fromMap(Map<String, dynamic> map) {
    return ContractModel(
      id: map['id'] as int?,
      contractNumber: map['contract_number'] as String,
      departmentName: map['department_name'] as String,
      startDate: map['start_date'] as String?,
      endDate: map['end_date'] as String?,
      totalValue: map['total_value'] == null
          ? null
          : (map['total_value'] as num).toDouble(),
      status: map['status'] as String,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }
}
