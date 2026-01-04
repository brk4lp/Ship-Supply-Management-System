class Ship {
  final int id;
  final String name;
  final String imoNumber;
  final String flag;
  final String shipType;
  final double? grossTonnage;
  final String? owner;
  final DateTime createdAt;
  final DateTime updatedAt;

  Ship({
    required this.id,
    required this.name,
    required this.imoNumber,
    required this.flag,
    required this.shipType,
    this.grossTonnage,
    this.owner,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Ship.fromJson(Map<String, dynamic> json) {
    return Ship(
      id: json['id'] as int,
      name: json['name'] as String,
      imoNumber: json['imo_number'] as String,
      flag: json['flag'] as String,
      shipType: json['ship_type'] as String,
      grossTonnage: json['gross_tonnage'] != null
          ? (json['gross_tonnage'] as num).toDouble()
          : null,
      owner: json['owner'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imo_number': imoNumber,
      'flag': flag,
      'ship_type': shipType,
      'gross_tonnage': grossTonnage,
      'owner': owner,
    };
  }
}
