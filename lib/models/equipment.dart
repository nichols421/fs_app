class Equipment {
  final String id;
  final String serialNumber;
  final String partNumber;
  final String partName;
  final String customerNumber;
  final String customerName;
  final String? rfidData;
  final DateTime createdAt;
  final DateTime updatedAt;

  Equipment({
    required this.id,
    required this.serialNumber,
    required this.partNumber,
    required this.partName,
    required this.customerNumber,
    required this.customerName,
    this.rfidData,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'serialNumber': serialNumber,
      'partNumber': partNumber,
      'partName': partName,
      'customerNumber': customerNumber,
      'customerName': customerName,
      'rfidData': rfidData,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Equipment.fromMap(Map<String, dynamic> map) {
    return Equipment(
      id: map['id'],
      serialNumber: map['serialNumber'],
      partNumber: map['partNumber'],
      partName: map['partName'],
      customerNumber: map['customerNumber'],
      customerName: map['customerName'],
      rfidData: map['rfidData'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Equipment copyWith({
    String? id,
    String? serialNumber,
    String? partNumber,
    String? partName,
    String? customerNumber,
    String? customerName,
    String? rfidData,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Equipment(
      id: id ?? this.id,
      serialNumber: serialNumber ?? this.serialNumber,
      partNumber: partNumber ?? this.partNumber,
      partName: partName ?? this.partName,
      customerNumber: customerNumber ?? this.customerNumber,
      customerName: customerName ?? this.customerName,
      rfidData: rfidData ?? this.rfidData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}