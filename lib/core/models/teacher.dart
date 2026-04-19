/// Teacher model
class Teacher {
  final int id;
  final String name;
  final String email;
  final String? phoneNumber;
  final List<String>? subjects;

  Teacher({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.subjects,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) {
    int? asInt(dynamic value) => value == null ? null : (value as num).toInt();

    final name =
        json['name'] as String? ??
        json['fullName'] as String? ??
        json['full_name'] as String? ??
        '${json['firstName'] ?? json['first_name'] ?? ''} ${json['lastName'] ?? json['last_name'] ?? ''}'
            .trim();

    return Teacher(
      id: asInt(json['id']) ?? 0,
      name: name.isNotEmpty ? name : 'Unknown',
      email: json['email'] as String,
      phoneNumber:
          json['phoneNumber'] as String? ?? json['phone_number'] as String?,
      subjects: switch (json['subjects'] ?? json['subject_ids']) {
        final List<dynamic> values =>
          values.map((value) => value.toString()).toList(),
        _ => null,
      },
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'subjects': subjects,
    };
  }

  String get fullName => name;
  String get firstName => name.split(' ').first;
  String get lastName => name.split(' ').skip(1).join(' ');
}
