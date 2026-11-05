/// The signed-in person.
class AppUser {
  const AppUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.email,
    required this.userType,
    required this.role,
    this.organizationId,
    this.departmentId,
  });

  final int id;
  final String firstName;
  final String lastName;
  final String fullName;
  final String email;

  /// founder, admin, manager or employee.
  final String userType;

  /// The job title shown to people, for example "Founder".
  final String role;

  final int? organizationId;
  final int? departmentId;

  bool get isFounder => userType == 'founder';

  /// The name to show: the full name, else the email.
  String get displayName => fullName.isNotEmpty ? fullName : email;

  /// What to show under the name: the job title, else the account type.
  String get roleLabel {
    if (role.isNotEmpty) return role;
    if (userType.isEmpty) return '';
    return userType[0].toUpperCase() + userType.substring(1);
  }
}
