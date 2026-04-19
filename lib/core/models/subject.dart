/// Subject model
class Subject {
  final int id;
  final String name;
  final String? code;
  final String? description;

  Subject({required this.id, required this.name, this.code, this.description});

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'code': code, 'description': description};
  }
}
