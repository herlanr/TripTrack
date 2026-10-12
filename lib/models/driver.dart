class Driver {
  const Driver({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
  });

  final String id;
  final String firstName;
  final String lastName;
  final DateTime dateOfBirth;

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'dateOfBirth': dateOfBirth.toIso8601String(),
      };

  factory Driver.fromJson(Map<String, dynamic> json) => Driver(
        id: json['id'] as String,
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
        dateOfBirth: DateTime.parse(json['dateOfBirth'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Driver && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
