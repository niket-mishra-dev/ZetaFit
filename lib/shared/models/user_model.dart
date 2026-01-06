class UserModel {
  final String id;
  final String? name;
  final int? age;
  final String? gender;
  final double? height;
  final double? weight;

  UserModel({
    required this.id,
    this.name,
    this.age,
    this.gender,
    this.height,
    this.weight,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      name: map['name'] as String?,
      age: map['age'] as int?,
      gender: map['gender'] as String?,
      height: (map['height'] as num?)?.toDouble(),
      weight: (map['weight'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
    };
  }
}
